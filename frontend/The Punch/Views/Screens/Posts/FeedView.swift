import SwiftUI

struct FeedView: View {
    @State private var posts: [FeedPost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasMore = false
    @State private var currentOffset = 0
    @State private var daysBack = 2
    @State private var includeOwnPosts = false
    
    @StateObject private var authManager = AuthManager.shared
    
    private let pageSize = 20
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
                
                // Main content
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
                                Task { await loadFeed() }
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }
                        .padding()
                    } else if posts.isEmpty {
                        EmptyFeedView()
                    } else {
                        ScrollView {
                            // Filter Bar
                            FeedFilterBar(
                                daysBack: $daysBack,
                                includeOwnPosts: $includeOwnPosts,
                                onApply: {
                                    Task { await loadFeed() }
                                }
                            )
                            .padding(.horizontal, 12)
                            .padding(.top, 10)
                            
                            VStack(spacing: 16) {
                                ForEach(posts) { post in
                                    FeedPostCard(post: post)
                                        .padding(.horizontal, 12)
                                    
                                    // Load more when reaching the last post
                                    if post == posts.last && hasMore && !isLoading {
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
                        .refreshable {
                            await loadFeed()
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .toolbarBackground(Color(red: 0.12, green: 0.10, blue: 0.10), for: .navigationBar)
            .toolbarColorScheme(.dark)
            .task {
                await loadFeed()
            }
        }
        .tabItem {
            Label("Home", systemImage: "house.fill")
        }
    }
    
    // Load initial feed
    @MainActor
    private func loadFeed() async {
        print("\n🔍 DEBUG: Starting loadFeed()")
        print("🔍 AuthManager token exists: \(authManager.token != nil)")
        
        guard let token = authManager.token else {
            errorMessage = "You're not logged in."
            print("❌ No auth token - user not logged in")
            return
        }
        
        print("✅ Token found: \(token.prefix(30))...")
        
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        
        do {
            print("📡 Calling getUserFeed API...")
            let response = try await APIService.shared.getUserFeed(
                limit: pageSize,
                offset: 0,
                days: daysBack,
                includeOwn: includeOwnPosts,
                token: token
            )
            
            print("📥 Response received: success=\(response.success)")
            
            if response.success, let data = response.data {
                posts = data.posts
                hasMore = data.pagination.hasMore
                currentOffset = data.posts.count
                print("✅ Successfully loaded \(data.posts.count) posts")
            } else {
                errorMessage = response.message ?? "Failed to load feed"
                posts = []
                print("⚠️ API returned success=false: \(response.message ?? "no message")")
            }
        } catch {
            errorMessage = error.localizedDescription
            posts = []
            print("❌ CATCH BLOCK - Error type: \(type(of: error))")
            print("❌ Error details: \(error)")
            
            // Check for specific error types
            if let decodingError = error as? DecodingError {
                print("❌ DECODING ERROR - Response doesn't match expected structure")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: \(key)")
                    print("   Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: expected \(type)")
                    print("   Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type)")
                    print("   Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
        }
        
        isLoading = false
        print("🏁 loadFeed() completed\n")
        
        // END DEBUG
    }
    
    // Load more posts (pagination)
    @MainActor
    private func loadMore() async {
        guard let token = authManager.token, !isLoading, hasMore else { return }
        
        isLoading = true
        
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
            // Silently fail for pagination errors
            print("Load more error: \(error)")
        }
        
        isLoading = false
    }
}

// Feed Post Card Component
struct FeedPostCard: View {
    let post: FeedPost
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @StateObject private var authManager = AuthManager.shared
    
    init(post: FeedPost) {
        self.post = post
        self._isLiked = State(initialValue: post.engagement.userHasLiked)
        self._likeCount = State(initialValue: post.engagement.likeCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.user.displayNameOrUsername.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user.displayNameOrUsername)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("@\(post.user.username)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Feeling emoji
                if let emoji = post.feelingEmoji {
                    Text(emoji)
                        .font(.title2)
                }
                
                // Time
                Text(formatDate(post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Post Content
            Text(post.text)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            // Engagement Bar
            HStack(spacing: 24) {
                // Like Button
                Button(action: { toggleLike() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(likeCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Comment Button
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.gray)
                    Text("\(post.engagement.commentCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .font(.footnote)
        }
        .padding()
        .background(Color(red: 0.15, green: 0.13, blue: 0.13))
        .cornerRadius(12)
    }
    
    private func toggleLike() {
        Task {
            guard let token = authManager.token else { return }

            // Save previous UI state (for rollback)
            let prevLiked = isLiked
            let prevCount = likeCount

            // Optimistic update
            isLiked.toggle()
            likeCount += isLiked ? 1 : -1

            do {
                if isLiked {
                    // just liked
                    _ = try await APIService.shared.likePost(postId: post.id, token: token)
                } else {
                    // just unliked
                    _ = try await APIService.shared.unlikePost(postId: post.id, token: token)
                }
            } catch {
                // Rollback if server rejected it
                isLiked = prevLiked
                likeCount = prevCount
                print("Like toggle failed:", error.localizedDescription)
            }
        }
    }

    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            displayFormatter.doesRelativeDateFormatting = true
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// Filter Bar Component
struct FeedFilterBar: View {
    @Binding var daysBack: Int
    @Binding var includeOwnPosts: Bool
    let onApply: () -> Void
    
    var body: some View {
        HStack {
            Menu {
                ForEach([1, 2, 3, 7], id: \.self) { days in
                    Button("\(days) day\(days > 1 ? "s" : "")") {
                        daysBack = days
                        onApply()
                    }
                }
            } label: {
                Label("Last \(daysBack) day\(daysBack > 1 ? "s" : "")", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                includeOwnPosts.toggle()
                onApply()
            }) {
                HStack {
                    Image(systemName: includeOwnPosts ? "checkmark.square.fill" : "square")
                    Text("My posts")
                }
                .font(.caption)
                .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
    }
}

// Empty Feed View
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Posts Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Follow some people to see their posts here!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
