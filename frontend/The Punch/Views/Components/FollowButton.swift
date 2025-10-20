//  FollowButton.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/19/25.
//

import SwiftUI

struct FollowButton: View {
    @EnvironmentObject var auth: AuthManager

    let viewedUserId: Int

    @State private var isFollowing = false
    @State private var loading = false
    @State private var didLoadForThisUser = false

    var body: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(isFollowing ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isFollowing ? Color.white : Color(red: 0.95, green: 0.60, blue: 0.20))
                .clipShape(Capsule())
        }
        .disabled(loading || !canFollow)
        .opacity(loading ? 0.6 : 1.0)
        // Load on first appear and whenever the viewed user changes
        .task(id: viewedUserId) {
            await loadInitialState()
        }
        // If auth token/currentUser arrives later (e.g., post-login), refresh
        .onChange(of: auth.token) { _, _ in
            Task { await loadInitialState(force: true) }
        }
    }

    private var canFollow: Bool {
        guard let me = auth.currentUser else { return false }
        return me.id != viewedUserId
    }

    private func loadInitialState(force: Bool = false) async {
        guard canFollow, let token = auth.token else { return }
        if didLoadForThisUser && !force { return }

        do {
            let status = try await APIService.shared.checkIfFollowing(userId: viewedUserId, token: token)
            await MainActor.run {
                self.isFollowing = status.following
                self.didLoadForThisUser = true
            }
        } catch {
            //nit: add toast
        }
    }

    private func toggleFollow() async {
        guard canFollow, let token = auth.token else { return }
        await MainActor.run { loading = true }
        defer { Task { await MainActor.run { loading = false } } }

        do {
            if isFollowing {
                _ = try await APIService.shared.unfollowUser(userId: viewedUserId, token: token)
                await MainActor.run { isFollowing = false }
            } else {
                _ = try await APIService.shared.followUser(userId: viewedUserId, token: token)
                await MainActor.run { isFollowing = true }
            }
        } catch {
            //nit: add toast
        }
    }
}

