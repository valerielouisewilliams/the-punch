//
//  CloudinaryUploader.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/24/25.
//


import UIKit

struct CloudinaryUploader {
    
    static let cloudName = "dfo6fchsl"
    static let uploadPreset = "punch_profile_pics"
    
    static func uploadImage(_ image: UIImage) async throws -> String {
        guard let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload") else {
            throw NSError(domain: "Cloudinary", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Cloudinary URL"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Cloudinary", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }
        
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Cloudinary", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        // Parse JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let urlString = json?["secure_url"] as? String else {
            throw NSError(domain: "Cloudinary", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing URL in Cloudinary response"])
        }
        
        return urlString
    }
}
