import SwiftUI

struct UserProfileView: View {
    let userId: Int
    
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var user: User?
    @State private var posts: [Post] = []
    @State private var isLoadingUser = true
    @State private var isLoadingPosts = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    // Sheets
    @State private var showSettings = false
    @State private var showFollowers = false
    @State private var showFollowing = false
    
    // Prevent overlapping loads
    @State private var isFetching = false
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    if isLoadingUser {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding()
                    } else if let user {
                        ProfileHeaderView(
                            user: user,
                            postCount: posts.count,
                            onStatTap: { stat in
                                switch stat {
                                case .posts:
                                    // Posts are already shown below; you could add scroll-to-posts later using ScrollViewReader.
                                    break
                                case .followers:
                                    showFollowers = true
                                case .following:
                                    showFollowing = true
                                }
                            }
                        )
                        .padding(.top, 20)
                        
                        // ACTION ROW under header:
                        // Show Follow if it's someone else; otherwise show Settings (i.e. we're looking at our own profile)
                        if let me = authManager.currentUser, me.id != user.id {
                            FollowButton(viewedUserId: user.id)
                                .padding(.horizontal)
                        } else {
                            Button {
                                showSettings = true
                            } label: {
                                Text("Settings")
                                    .font(.system(size: 14, weight: .semibold))
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
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    // User's Posts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("POSTS")
                            .font(.system(size: 16, weight: .bold))
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
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("🥊")
                                    .font(.system(size: 40))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(posts.indices, id: \.self) { index in
                                NavigationLink {
                                    PostDetailView(post: $posts[index])
                                } label: {
                                    PostCard(post: posts[index], context: .profile)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        
        // SETTINGS SHEET
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onLoggedOut: {
                    user = nil
                    posts = []
                },
                onProfileUpdated: { updated in
                    self.user = updated
                }
            )
            .environmentObject(authManager)
        }

        
        // FOLLOWERS SHEET
        .sheet(isPresented: $showFollowers) {
            NavigationStack {
                if let user {
                    FollowersListView(userId: user.id)
                        .navigationTitle("Followers")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Unable to load followers.")
                        .foregroundColor(.white)
                        .background(Color.black.ignoresSafeArea())
                }
            }
        }
        
        // FOLLOWING SHEET
        .sheet(isPresented: $showFollowing) {
            NavigationStack {
                if let user {
                    FollowingListView(userId: user.id)
                        .navigationTitle("Following")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Unable to load following.")
                        .foregroundColor(.white)
                        .background(Color.black.ignoresSafeArea())
                }
            }
        }
        
        // DATA LOADING
        .task(id: userId) {
            await loadProfile()
        }
        .refreshable {
            await loadProfile()
        }
        
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .postDidUpdate)) { notif in
            guard
                let id = notif.userInfo?["id"] as? Int,
                let isLiked = notif.userInfo?["isLiked"] as? Bool,
                let likeCount = notif.userInfo?["likeCount"] as? Int
            else { return }

            if let index = posts.firstIndex(where: { $0.id == id }) {
                posts[index].stats.userHasLiked = isLiked
                posts[index].stats.likeCount = likeCount
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .commentDidCreate)) { notif in
            guard
                let postId = notif.userInfo?["postId"] as? Int
            else { return }

            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].stats.commentCount += 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .commentDidDelete)) { notif in
            guard
                let postId = notif.userInfo?["postId"] as? Int
            else { return }

            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].stats.commentCount = max(0, posts[index].stats.commentCount - 1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .followDidChange)) { notif in
            guard
                let targetId = notif.userInfo?["userId"] as? Int,
                let followerId = notif.userInfo?["followerId"] as? Int,
                let newState = notif.userInfo?["isFollowing"] as? Bool
            else { return }

            // CASE 1: I am viewing *someone else's profile*
            if user?.id == targetId {
                user?.isFollowing = newState
                if newState {
                    user?.followerCount? += 1
                } else {
                    user?.followerCount? = max(0, (user?.followerCount ?? 1) - 1)
                }
            }

            // CASE 2: I am viewing *my own profile* and I follow/unfollow someone
            if authManager.currentUser?.id == user?.id {
                if newState {
                    user?.followingCount? += 1
                } else {
                    user?.followingCount? = max(0, (user?.followingCount ?? 1) - 1)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .postDidDelete)) { notif in
            guard let id = notif.userInfo?["id"] as? Int else { return }

            // Remove the post instantly
            posts.removeAll { $0.id == id }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidUpdate)) { notif in
            guard let updatedId = notif.userInfo?["id"] as? Int else { return }

            // Only update if it's the same profile being viewed
            guard updatedId == userId else { return }

            if var u = user {
                if let displayName = notif.userInfo?["displayName"] as? String {
                    u.displayName = displayName
                }
                if let bio = notif.userInfo?["bio"] as? String {
                    u.bio = bio
                }
                if let avatar = notif.userInfo?["avatarUrl"] as? String {
                    u.avatarUrl = avatar
                }
                self.user = u
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidUpdate)) { notif in
            guard let updatedId = notif.userInfo?["id"] as? Int else { return }

            for i in posts.indices {
                if posts[i].author.id == updatedId {
                    if let displayName = notif.userInfo?["displayName"] as? String {
                        posts[i].author.displayName = displayName
                    }
                    if let avatar = notif.userInfo?["avatarUrl"] as? String {
                        posts[i].author.avatarUrl = avatar
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .postDidCreate)) { notif in
            // Support both patterns: userInfo["post"] and object as Post
            let newPost: Post?

            if let p = notif.userInfo?["post"] as? Post {
                newPost = p
            } else if let p = notif.object as? Post {
                newPost = p
            } else {
                return
            }

            guard let post = newPost else { return }

            // Only insert if this is the profile we're currently viewing
            guard post.author.id == userId else { return }

            // Put newest at the top
            posts.insert(post, at: 0)
        }

    }
    
    
    // MARK: - Networking
    
    private func loadProfile() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        
        await loadUser()
        await loadPosts()
    }
    
    private func loadUser() async {
        await MainActor.run { isLoadingUser = true }

        let token: String
        do {
            token = try await authManager.firebaseIdToken()
        } catch {
            await MainActor.run {
                isLoadingUser = false
                errorMessage = "You're not logged in."
                showError = true
            }
            return
        }

        do {
            let response = try await APIService.shared.getUserProfile(
                userId: userId,
                token: token
            )

            await MainActor.run {
                self.user = response.data
                self.isLoadingUser = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingUser = false
                self.errorMessage = "Failed to load user profile."
                self.showError = true
            }
            print("loadUser error:", error)
        }
    }
    
    func loadPosts() async {
        await MainActor.run { isLoadingPosts = true }

        let token: String
        do {
            token = try await authManager.firebaseIdToken()
        } catch {
            await MainActor.run {
                isLoadingPosts = false
            }
            return
        }

        do {
            let response = try await APIService.shared.getUserPosts(userId: userId)

            await MainActor.run {
                self.posts = response.data
                self.isLoadingPosts = false
            }
        } catch {
            print("Error loading posts:", error)
            await MainActor.run {
                self.isLoadingPosts = false
            }
        }
    }
}

