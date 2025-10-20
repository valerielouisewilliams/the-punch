import SwiftUI

struct UserProfileView: View {
    let userId: Int

    @ObservedObject private var authManager = AuthManager.shared

    @State private var user: User?
    @State private var posts: [Post] = []
    @State private var isLoadingUser = true
    @State private var isLoadingPosts = true
    @State private var errorMessage = ""
    @State private var showError = false

    // Settings sheet
    @State private var showSettings = false

    // Prevent overlapping loads
    @State private var isFetching = false

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    if isLoadingUser {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding()
                    } else if let user {
                        ProfileHeaderView(user: user)
                            .padding(.top, 20)

                        // ACTION ROW under header:
                        // Show Follow if it's someone else; otherwise show Settings (i.e. we're looking at our own profile)
                        if let me = authManager.currentUser, me.id != user.id {
                            FollowButton(viewedUserId: user.id)
                                .environmentObject(authManager)
                                .padding(.horizontal)
                        } else {
                            Button {
                                showSettings = true
                            } label: {
                                Text("Settings")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 18)
                                    .background(Color(red: 0.95, green: 0.60, blue: 0.20))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Text("User not found")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding()
                    }

                    // User's Posts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("POSTS")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                            .padding(.horizontal)

                        if isLoadingPosts {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if posts.isEmpty {
                            VStack(spacing: 8) {
                                Text("No posts yet")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("🥊").font(.system(size: 40))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(posts) { post in
                                PostCard(post: post)
                                    .environmentObject(authManager)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)

        // PRESENT SETTINGS SHEET
        .sheet(isPresented: $showSettings) {
            SettingsView {
                // After logout, clear local UI
                user = nil
                posts = []
            }
            .environmentObject(authManager)
        }

        // DATA LOADING
        .task(id: userId) { await loadProfile() }
        .refreshable { await loadProfile() }

        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: { Text(errorMessage) }
    }

    // Networking

    private func loadProfile() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        await loadUser()
        await loadPosts()
    }

    private func loadUser() async {
        await MainActor.run { isLoadingUser = true }
        do {
            let token = authManager.getToken()
            let response = try await APIService.shared.getUserProfile(userId: userId, token: token)
            await MainActor.run {
                self.user = response.data
                self.isLoadingUser = false
            }
        } catch {
            await MainActor.run {
                self.user = nil
                self.isLoadingUser = false
                self.errorMessage = "Failed to load profile"
                self.showError = true
            }
        }
    }

    private func loadPosts() async {
        await MainActor.run { isLoadingPosts = true }
        do {
            let token = authManager.getToken()
            let response = try await APIService.shared.getUserPosts(userId: userId, token: token)
            await MainActor.run {
                self.posts = response.data
                self.isLoadingPosts = false
            }
        } catch {
            await MainActor.run {
                self.posts = []
                self.isLoadingPosts = false
                self.errorMessage = "Failed to load posts"
                self.showError = true
            }
        }
    }
}
