//
//  UserLookup.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/19/25.
//

import Foundation

@MainActor
final class UserLookup: ObservableObject {
    static let shared = UserLookup()
    private init() {}

    @Published private var names: [Int: String] = [:]

    func username(for userId: Int) -> String? { names[userId] }

    func loadUsername(for userId: Int, token: String?) async {
        if names[userId] != nil { return }
        do {
            let resp = try await APIService.shared.getUserProfile(userId: userId, token: token)
            names[userId] = resp.data.username
        } catch {
            // fallback label on failure
            names[userId] = "user\(userId)"
            print("Username lookup failed: \(error)")
        }
    }
}
