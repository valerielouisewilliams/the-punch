//
//  GoogleSignInHandler.swift
//  ThePunch
//
//  Created by Sydney Patel on 3/24/26.
//

import Foundation
import GoogleSignIn
import FirebaseAuth

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
