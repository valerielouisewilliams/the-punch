//
//  GoogleSignInHandler.swift
//  ThePunch
//
//  Created by Sydney Patel on 3/24/26.
//

import Foundation
import GoogleSignIn
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import UIKit
import Security

@MainActor
final class GoogleSignInHandler: ObservableObject {

    func signIn() async throws {
        // Find the top-most view controller to present the Google sheet from
        guard let rootViewController = await topViewController() else {
            throw GoogleSignInError.noRootViewController
        }

        // Present the Google sign-in sheet
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.missingToken
        }

        let accessToken = result.user.accessToken.tokenString

        // Exchange Google tokens for a Firebase credential
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        // Sign into Firebase
        try await Auth.auth().signIn(with: credential)

        // Sync with your backend (same flow as email/password)
        try await AuthManager.shared.syncSessionWithBackend()
    }

    private func topViewController() async -> UIViewController? {
        await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
            else { return nil }
            return window.rootViewController?.topmostViewController()
        }
    }
}

@MainActor
final class AppleSignInHandler: ObservableObject {
    private var currentNonce: String?

    func prepare(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handle(result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .failure(let error):
            throw error

        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AppleSignInError.invalidCredential
            }

            guard let nonce = currentNonce else {
                throw AppleSignInError.invalidState
            }

            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AppleSignInError.missingToken
            }

            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                rawNonce: nonce
            )

            try await Auth.auth().signIn(with: credential)
            try await AuthManager.shared.syncSessionWithBackend()
        }
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms: [UInt8] = Array(repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}

enum GoogleSignInError: LocalizedError {
    case noRootViewController
    case missingToken

    var errorDescription: String? {
        switch self {
        case .noRootViewController: return "Unable to present sign-in screen."
        case .missingToken:         return "Google sign-in failed. Please try again."
        }
    }
}

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case invalidState
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Apple sign-in failed. Please try again."
        case .invalidState:
            return "Apple sign-in request expired. Please try again."
        case .missingToken:
            return "Missing Apple identity token. Please try again."
        }
    }
}

private extension UIViewController {
    func topmostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topmostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topmostViewController() ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topmostViewController() ?? self
        }
        return self
    }
}
