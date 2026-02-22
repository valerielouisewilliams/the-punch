import SwiftUI

struct FeedView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasMore = false
    @State private var currentOffset = 0
    @State private var daysBack = 3
    @State private var includeOwnPosts = true

    @StateObject private var authManager = AuthManager.shared

    private let pageSize = 20

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

                Group {
                    if isLoading && posts.isEmpty {
                        ProgressView("Loading feed…")
                            .tint(.white)
                    } else if let errorMessage {
                        VStack(spacing: 12) {
                            Text("Couldn't load your feed.")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text(errorMessage)
                                .foregroundColor(.gray)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await reloadFeed() }
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }
                        .padding()
                    } else if posts.isEmpty {
                        Text("No Posts!")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(posts.indices, id: \.self) { index in
                                    NavigationLink {
                                        PostDetailView(post: $posts[index])
                                    } label: {
                                        PostCard(post: posts[index])
                                            .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)

                                    // Infinite scroll trigger
                                    if index == posts.count - 1 && hasMore && !isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .onAppear {
                                                Task { await loadMore() }
                                            }
                                    }
                                }

                            }
                            .padding(.top, 10)
                        }
                        .refreshable { await reloadFeed() }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Home 🏡")
            .toolbarBackground(Color(red: 0.12, green: 0.10, blue: 0.10), for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        Task { SoundManager.shared.playSound(.refresh)
                            await reloadFeed() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Reload")
                }
            }
            .task { await reloadFeed() }
            .onChange(of: includeOwnPosts) { _ in Task { await reloadFeed() } }
            .onChange(of: daysBack) { _ in Task { await reloadFeed() } }
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
        .onReceive(NotificationCenter.default.publisher(for: .postDidCreate)) { notif in
            guard let newPost = notif.userInfo?["post"] as? Post else { return }

            // Only add if includeOwnPosts = true OR post isn't by me
            if includeOwnPosts || newPost.author.id != authManager.currentUser?.id {
                posts.insert(newPost, at: 0)
            }
        }

        .tabItem { Label("Home", systemImage: "house.fill") }
    }
    

    // MARK: - Data

    @MainActor
    private func reloadFeed() async {
        errorMessage = nil
        posts = []
        currentOffset = 0
        hasMore = false
        await loadFeed(offset: 0, replacing: true)
    }

    @MainActor
    private func loadFeed(offset: Int, replacing: Bool) async {
        // Fetch Firebase token on demand
        let token: String
        do {
            token = try await authManager.firebaseIdToken()
        } catch {
            errorMessage = "You're not logged in."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.getUserFeed(
                limit: pageSize,
                offset: offset,
                days: daysBack,
                includeOwn: includeOwnPosts,
                token: token
            )

            if response.success, let data = response.data {
                if replacing {
                    posts = data.posts
                    currentOffset = data.posts.count
                } else {
                    posts.append(contentsOf: data.posts)
                    currentOffset += data.posts.count
                }
                hasMore = data.pagination.hasMore
            } else {
                errorMessage = response.message ?? "Failed to load feed."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func loadMore() async {
        guard !isLoading, hasMore else { return }

        // Fetch Firebase token on demand
        let token: String
        do {
            token = try await authManager.firebaseIdToken()
        } catch {
            // soft-fail pagination
            print("Not logged in; can't paginate.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.getUserFeed(
                limit: pageSize,
                offset: currentOffset,
                days: daysBack,
                includeOwn: includeOwnPosts,
                token: token
            )

            if response.success, let data = response.data {
                posts.append(contentsOf: data.posts)
                hasMore = data.pagination.hasMore
                currentOffset += data.posts.count
            }
        } catch {
            // soft-fail pagination
            print("Load more error:", error)
        }
    }
}

