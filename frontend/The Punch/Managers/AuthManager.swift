//
//  AuthManager.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/10/25.
//

import Foundation
import SwiftUI

/**
 AuthManager handles all authentication-related functionality.
 - Observable & persistent
 - Publishes token / user changes to the UI
 */
@MainActor
final class AuthManager: ObservableObject {
    // Singleton
    static let shared = AuthManager()
    private init() {
        migrateLegacyTokenKeyIfNeeded()

        // Load persisted token & user at launch
        self.token = UserDefaults.standard.string(forKey: Keys.token)
        if let data = UserDefaults.standard.data(forKey: Keys.user),
           let u = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = u
        }

        // Derive isAuthenticated from whether we have a token or not
        self.isAuthenticated = (self.token != nil)

        // If we have a token but no user, optionally refresh from server
        if self.token != nil, self.currentUser == nil {
            Task { await loadCurrentUser() }
        }
    }

    // Storage Keys
    private enum Keys {
        static let token = "authToken"
        static let user  = "auth_user"
        // legacy key we used before
        static let legacyToken = "auth_token"
    }

    // Published State
    @Published var isAuthenticated: Bool = false

    /// Persisted auth token (string). Changing this updates UserDefaults and `isAuthenticated`
    @Published var token: String? {
        didSet {
            if let token {
                UserDefaults.standard.set(token, forKey: Keys.token)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.token)
            }
            isAuthenticated = (token != nil)
        }
    }

    /// Persisted current user. Changing this updates UserDefaults.
    @Published var currentUser: User? {
        didSet {
            if let user = currentUser, let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: Keys.user)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.user)
            }
        }
    }

    // Session Lifecycle

    /// Call this right after a successful login.
    func completeLogin(user: User, token: String) {
        self.token = token           // persists + flips isAuthenticated
        self.currentUser = user      // persists
    }

    /// Load the current user from the backend using the stored token.
    func loadCurrentUser() async {
        guard let token = self.token else {
            print("No token; cannot load current user.")
            return
        }
        do {
            let response = try await APIService.shared.getCurrentUser(token: token)
            self.currentUser = response.data
            print("Loaded user: \(response.data.username)")
        } catch {
            print("Failed to load user: \(error.localizedDescription)")
            // If unauthorized/expired token, clear session
            if "\(error)".localizedCaseInsensitiveContains("unauthorized")
                || "\(error)".localizedCaseInsensitiveContains("token") {
                logout()
            }
        }
    }

    /// Update local cached user after profile edits.
    func updateUser(_ user: User) {
        self.currentUser = user
    }

    /// Log out: clear token + user and notify UI.
    func logout() {
        print("Logging out...")
        self.token = nil
        self.currentUser = nil
        print("Logged out.")
    }

    // Legacy helpers (optional)
    func saveToken(_ token: String) { self.token = token }
    func getToken() -> String? { self.token }
    func hasValidToken() -> Bool { self.token != nil }

    // Migration
    /// If we previously saved under "auth_token", move it to "authToken" so @AppStorage("authToken") can read it.
    private func migrateLegacyTokenKeyIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: Keys.token) == nil,
           let legacy = defaults.string(forKey: Keys.legacyToken) {
            defaults.set(legacy, forKey: Keys.token)
            defaults.removeObject(forKey: Keys.legacyToken)
            #if DEBUG
            print("🔁 Migrated legacy token to key '\(Keys.token)'")
            #endif
        }
    }

    // Debug stuff
    func printDebugInfo() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("AUTH MANAGER DEBUG INFO")
        print("isAuthenticated: \(isAuthenticated)")
        print("Has token: \(token != nil)")
        print("Current user: \(currentUser?.username ?? "none")")
        if let token = token { print("Token (first 20): \(token.prefix(20))...") }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
