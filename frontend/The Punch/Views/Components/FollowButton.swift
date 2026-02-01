import SwiftUI

struct FollowButton: View {
    @ObservedObject private var auth = AuthManager.shared
    let viewedUserId: Int

    @State private var isFollowing = false
    @State private var loading = false

    var body: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isFollowing ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isFollowing ? Color.white : Color(red: 0.95, green: 0.60, blue: 0.20))
                .clipShape(Capsule())
        }
        .disabled(loading || !canFollow)
        .opacity(loading ? 0.6 : 1.0)

        // load whenever the viewed user changes
        .task(id: viewedUserId) {
            await loadInitialState()
        }

        // refresh when auth state changes (login/logout)
        .task(id: auth.currentUser?.id) {
            await loadInitialState()
        }
    }

    private var canFollow: Bool {
        guard let me = auth.currentUser else { return false }
        return me.id != viewedUserId
    }

    private func loadInitialState() async {
        guard canFollow else { return }

        do {
            // Get a fresh Firebase ID token on-demand
            let token = try await auth.firebaseIdToken()

            let status = try await APIService.shared.checkIfFollowing(
                userId: viewedUserId,
                token: token
            )

            await MainActor.run {
                self.isFollowing = status.following
            }
        } catch {
            print("checkIfFollowing failed:", error)
        }
    }

    private func toggleFollow() async {
        guard canFollow else { return }

        await MainActor.run { loading = true }
        defer { Task { await MainActor.run { loading = false } } }

        SoundManager.shared.playSound(.follow)

        do {
            // Get a fresh token right before the request
            let token = try await auth.firebaseIdToken()

            if isFollowing {
                _ = try await APIService.shared.unfollowUser(
                    userId: viewedUserId,
                    token: token
                )
                await MainActor.run { isFollowing = false }
            } else {
                _ = try await APIService.shared.followUser(
                    userId: viewedUserId,
                    token: token
                )
                await MainActor.run { isFollowing = true }
            }

            NotificationCenter.default.post(
                name: .followDidChange,
                object: nil,
                userInfo: [
                    "userId": viewedUserId,
                    "followerId": auth.currentUser?.id ?? 0,
                    "isFollowing": isFollowing
                ]
            )
        } catch {
            print("toggleFollow failed:", error)
        }
    }
}
