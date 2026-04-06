//
//  AuthManager.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/10/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private init() {
        // Keep persisted user cache if you want
        if let data = UserDefaults.standard.data(forKey: Keys.user),
           let u = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = u
        }

        // Listen to Firebase auth state
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.isAuthenticated = (user != nil)
            self.isEmailVerified = user?.isEmailVerified ?? false

            // If we just logged in and don't have an app user yet, load it
            if user != nil, self.currentUser == nil {
                Task { await self.loadCurrentUserFromBackend() }
            }

            // If logged out, clear cached user
            if user == nil {
                self.currentUser = nil
            }
        }
    }

    private var authListener: AuthStateDidChangeListenerHandle?

    private enum Keys {
        static let user = "auth_user"
    }

    @Published var isAuthenticated: Bool = false
    @Published var isEmailVerified: Bool = false

    var requiresEmailVerification: Bool {
        guard let user = Auth.auth().currentUser else { return false }
        let providers = user.providerData.map { $0.providerID }
        return providers.contains("password")
    }

    @Published var currentUser: User? {
        didSet {
            if let user = currentUser, let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: Keys.user)
                Task {
                    do {
                        let token = try await firebaseIdToken()
                        appLog("Firebase Token:", token)
                    } catch {
                        appLog("Error getting Firebase token:", error)
                    }
                }
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.user)
            }
        }
    }

    // Fetch Firebase ID token on demand
    func firebaseIdToken(forceRefresh: Bool = true) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.noToken
        }
        return try await withCheckedThrowingContinuation { cont in
            user.getIDTokenForcingRefresh(forceRefresh) { token, err in
                if let err = err { cont.resume(throwing: err); return }
                cont.resume(returning: token ?? "")
            }
        }
    }

    // After Firebase login/register, call backend to “sync” user + get app user
    func syncSessionWithBackend() async throws {
        let token = try await firebaseIdToken()
        let me = try await APIService.shared.createSession(firebaseToken: token)
        self.currentUser = me.data
    }

    func loadCurrentUserFromBackend() async {
        do {
            let token = try await firebaseIdToken()
            let response = try await APIService.shared.getCurrentUser(firebaseToken: token)
            self.currentUser = response.data
        } catch {
            appLog("Failed to load current user:", error)
        }
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw APIError.noToken
        }
        try await user.sendEmailVerification()
    }

    func refreshEmailVerificationStatus() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw APIError.noToken
        }

        try await user.reload()
        let verified = Auth.auth().currentUser?.isEmailVerified ?? false
        self.isEmailVerified = verified

        if verified, self.currentUser == nil {
            try await syncSessionWithBackend()
        }

        return verified
    }
    // Full logout
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            appLog("Firebase signOut failed:", error)
        }
        currentUser = nil
    }
}
