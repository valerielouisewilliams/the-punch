//
//  FeedView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

/**
 The view that allows users to see their feed (i.e. posts from users that they follow)
 */
struct FeedView: View {
    @State private var posts: [Post] = []
    @AppStorage("authToken") private var authToken: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                            Text("Couldn’t load your feed.")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text(errorMessage)
                                .foregroundColor(.gray)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await loadFeed() }   // 👈 CALL loadFeed() on retry
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(posts) { post in
                                    PostCard(post: post)
                                        .padding(.horizontal, 12)
                                }
                            }
                            .padding(.top, 10)
                        }
                        // Pull-to-refresh calls loadFeed() again
                        .refreshable {
                            await loadFeed()
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .toolbarBackground(Color(red: 0.12, green: 0.10, blue: 0.10), for: .navigationBar)
            .toolbarColorScheme(.dark)
            // Run loadFeed() once when the view first appears
            .task {
                #if DEBUG
                print("authToken present? \(authToken.isEmpty ? "NO" : "YES")")
                if !authToken.isEmpty { print("authToken prefix:", authToken.prefix(12), "...") }
                #endif
                
                await loadFeed()
            }
        }
        .tabItem {
            Label("Home", systemImage: "house.fill")
        }
    }

    // Load Feed Function //TODO: major overhaul + fix
    @MainActor
    private func loadFeed() async {
        guard !authToken.isEmpty else {
            errorMessage = "You’re not logged in."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let resp = try await APIService.shared.getFeed(limit: 50, offset: 0, token: authToken)
            posts = resp.data
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

