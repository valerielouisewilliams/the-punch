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

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCard(post: post)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.top, 10)
                }
                .navigationTitle("Home")
                .toolbarBackground(Color(red: 0.12, green: 0.10, blue: 0.10), for: .navigationBar)
                .toolbarColorScheme(.dark)
            }
            .onAppear {
                loadFakePosts()
            }
        }
        .tabItem {
            Label("Home", systemImage: "house.fill")
        }
    }
    
    private func loadFakePosts() {
        posts = Post.samplePosts()
    }
}
