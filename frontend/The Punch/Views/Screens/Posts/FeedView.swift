import SwiftUI

struct FeedView: View {
    @State private var posts: [Post] = []
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
                                ForEach(posts) { post in
                                    PostCard(post: post)
                                        .padding(.horizontal, 12)

                                    // Infinite scroll trigger
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
                        .refreshable { await reloadFeed() }
                    }
                }
            }
            .navigationTitle("Home")
            .toolbarBackground(Color(red: 0.12, green: 0.10, blue: 0.10), for: .navigationBar)
            .toolbarColorScheme(.light)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Time window", selection: $daysBack) {
                            Text("Last 24 hours").tag(1)
                            Text("Last 2 days").tag(2)
                            Text("Last 3 days").tag(3)
                            Text("Last 7 days").tag(7)
                        }
                        Toggle("Include my posts", isOn: $includeOwnPosts)
                        Button("Apply filters") {
                            Task { await reloadFeed() }
                        }
                    } label: {
                        Label("Filters", systemImage: "slider.horizontal.3")
                            .foregroundStyle(.white)
                    }

                    Button {
                        Task { await reloadFeed() }
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
        guard let token = authManager.token else {
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
        guard !isLoading, hasMore, let token = authManager.token else { return }
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

