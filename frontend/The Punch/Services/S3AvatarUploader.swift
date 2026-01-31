//
//  S3AvatarUploader.swift
//  ThePunch
//
//  Created by Valerie Williams on 1/29/26.
//

import UIKit

enum S3UploadError: LocalizedError {
    case invalidPresignURL
    case invalidResponse
    case presignFailed(status: Int, body: String)
    case uploadFailed(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidPresignURL: return "Invalid presigned upload URL."
        case .invalidResponse: return "Invalid response from server."
        case .presignFailed(let status, let body): return "Presign failed (\(status)): \(body)"
        case .uploadFailed(let status, let body): return "Upload failed (\(status)): \(body)"
        }
    }
}

struct PresignAvatarResponse: Decodable {
    struct Payload: Decodable {
        let uploadUrl: String
        let publicUrl: String
        let key: String?
    }
    let success: Bool
    let data: Payload
}

struct S3AvatarUploader {

    /// Uses backend to presign, then uploads directly to S3.
    /// Returns the final public URL to store in avatarUrl / avatar_url.
    static func uploadAvatar(
        _ image: UIImage,
        apiBaseURL: URL,          // e.g. http://3.130.171.129:3000/api
        token: String
    ) async throws -> String {
        let token = try await AuthManager.shared.firebaseIdToken()
        
        // 1) Convert image -> data
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "S3Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }
        let contentType = "image/jpeg"

        // 2) Ask backend for presigned URL
        let presignURL = apiBaseURL.appendingPathComponent("media/presign/avatar")

        var presignRequest = URLRequest(url: presignURL)
        presignRequest.httpMethod = "POST"
        presignRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        presignRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        presignRequest.httpBody = try JSONSerialization.data(withJSONObject: [
            "contentType": contentType
        ])

        let (presignData, presignResp) = try await URLSession.shared.data(for: presignRequest)
        guard let presignHTTP = presignResp as? HTTPURLResponse else { throw S3UploadError.invalidResponse }

        if !(200...299).contains(presignHTTP.statusCode) {
            let body = String(data: presignData, encoding: .utf8) ?? ""
            throw S3UploadError.presignFailed(status: presignHTTP.statusCode, body: body)
        }

        let decoded = try JSONDecoder().decode(PresignAvatarResponse.self, from: presignData)
        guard decoded.success else { throw S3UploadError.invalidResponse }
        guard let uploadURL = URL(string: decoded.data.uploadUrl) else { throw S3UploadError.invalidPresignURL }

        // 3) PUT image directly to S3 using the presigned URL
        var putRequest = URLRequest(url: uploadURL)
        putRequest.httpMethod = "PUT"
        putRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (uploadRespData, uploadResp) = try await URLSession.shared.upload(for: putRequest, from: imageData)
        guard let uploadHTTP = uploadResp as? HTTPURLResponse else { throw S3UploadError.invalidResponse }

        if !(200...299).contains(uploadHTTP.statusCode) {
            let body = String(data: uploadRespData, encoding: .utf8) ?? ""
            throw S3UploadError.uploadFailed(status: uploadHTTP.statusCode, body: body)
        }

        // 4) Return the final URL (store this in avatarUrl)
        return decoded.data.publicUrl
    }
}
