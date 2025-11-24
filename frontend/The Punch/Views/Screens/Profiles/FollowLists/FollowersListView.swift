import SwiftUI

struct FollowersListView: View {
    let userId: Int

    @ObservedObject private var authManager = AuthManager.shared

    @State private var followers: [UserProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            if !isLoading && followers.isEmpty && errorMessage == nil {
                Text("No followers yet.")
                    .foregroundColor(.gray)
            }

            ForEach(followers) { user in
                NavigationLink {
                    UserProfileView(userId: user.id)
                } label: {
                    UserRow(user: user)
                }
                .listRowBackground(Color.clear)
            }

            if isLoading && followers.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFollowers()
        }
        .refreshable {
            await loadFollowers()
        }
    }

    private func loadFollowers() async {
        guard !isLoading else { return }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let token = authManager.getToken()
            let response = try await APIService.shared.getFollowersList(
                userId: userId,
                token: token
            )

            await MainActor.run {
                self.followers = response.followers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                if let apiError = error as? APIError {
                    self.errorMessage = apiError.errorDescription ?? "Failed to load followers."
                } else {
                    self.errorMessage = "Failed to load followers."
                }
            }
            print("Followers load error:", error)
        }
    }
}

