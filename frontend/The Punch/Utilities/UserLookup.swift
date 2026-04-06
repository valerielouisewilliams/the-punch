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
    @Published private var idsByUsername: [String: Int] = [:]

    func username(for userId: Int) -> String? { names[userId] }

    func loadUsername(for userId: Int, token: String?) async {
        if names[userId] != nil { return }
        do {
            let resp = try await APIService.shared.getUserProfile(userId: userId, token: token)
            names[userId] = resp.data.username
            idsByUsername[resp.data.username.lowercased()] = userId
        } catch {
            // fallback label on failure
            names[userId] = "user\(userId)"
            appLog("Username lookup failed: \(error)")
        }
    }

    func userId(for username: String) -> Int? {
        idsByUsername[username.lowercased()]
    }

    func loadUserId(for username: String, token: String? = nil) async -> Int? {
        let key = username.lowercased()
        if let cached = idsByUsername[key] { return cached }

        do {
            let resp = try await APIService.shared.getUserByUsername(username: username, token: token)
            idsByUsername[key] = resp.data.id
            names[resp.data.id] = resp.data.username
            return resp.data.id
        } catch {
            appLog("User ID lookup failed for @\(username): \(error)")
            return nil
        }
    }
}

struct MentionTextHelper {
    static func currentMentionQuery(in text: String) -> String? {
        let pattern = "(?:^|\\s)@([A-Za-z0-9_]*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        let queryRange = match.range(at: 1)
        guard let swiftRange = Range(queryRange, in: text) else { return nil }
        return String(text[swiftRange])
    }

    static func applyMentionCompletion(in text: String, username: String) -> String {
        let pattern = "(?:^|\\s)@[A-Za-z0-9_]*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range, in: text) else {
            return text
        }

        let token = String(text[matchRange])
        let hasLeadingSpace = token.hasPrefix(" ")
        let replacement = "\(hasLeadingSpace ? " " : "")@\(username) "
        return text.replacingCharacters(in: matchRange, with: replacement)
    }
}

@MainActor
final class MentionAutocompleteViewModel: ObservableObject {
    @Published var suggestions: [UserProfile] = []
    @Published var isVisible: Bool = false

    private var followingCache: [UserProfile] = []
    private var followingLoadedForUserId: Int?

    func refreshSuggestions(for text: String, currentUserId: Int?) async {
        guard let query = MentionTextHelper.currentMentionQuery(in: text) else {
            isVisible = false
            suggestions = []
            return
        }

        isVisible = true

        await loadFollowingIfNeeded(currentUserId: currentUserId)

        let queryLower = query.lowercased()
        let followedMatches = followingCache.filter {
            queryLower.isEmpty || $0.username.lowercased().hasPrefix(queryLower)
        }

        var merged: [UserProfile] = Array(followedMatches.prefix(8))

        if !queryLower.isEmpty {
            do {
                let remote = try await APIService.shared.searchUsers(query: query)
                for candidate in remote.data {
                    if merged.contains(where: { $0.id == candidate.id }) { continue }
                    merged.append(candidate)
                    if merged.count >= 8 { break }
                }
            } catch {
                appLog("Mention search failed: \(error)")
            }
        }

        suggestions = merged
        isVisible = !merged.isEmpty
    }

    func hide() {
        isVisible = false
        suggestions = []
    }

    private func loadFollowingIfNeeded(currentUserId: Int?) async {
        guard let userId = currentUserId else { return }
        if followingLoadedForUserId == userId { return }

        do {
            let resp = try await APIService.shared.getFollowingList(userId: userId)
            followingCache = resp.following
            followingLoadedForUserId = userId
        } catch {
            appLog("Failed loading following list for mention suggestions: \(error)")
            followingCache = []
            followingLoadedForUserId = userId
        }
    }
}
