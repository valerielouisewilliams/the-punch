//
//  UserProfileView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

/**
 The view that shows a user's profile.
 */
struct UserProfileView: View {
    let userID: UUID
    let isOwnProfile: Bool
    
    @State private var user: User?
    @State private var posts: [Post] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let user = user {
                    UserProfileHeader(user: user, isOwnProfile: isOwnProfile)
                } else {
                    ProgressView()
                        .tint(.white)
                        .padding()
                }
                
                // Fake posts for now (backend not connected yet)
                ForEach(posts) { post in
                    PostCard(post: post)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 60) // spacing above tab bar
        }
        .background(Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadFakeProfile()
        }
    }
    
    // Demo Fake Data
    private func loadFakeProfile() {
        user = User(
            id: userID,
            username: "val",
            displayName: "Valerie Williams",
            bio: "Creating👩‍💻",
            punches: 1293,
            friends: 219,
            streak: 829,
            feeling: "Productive",
            emoji: "😍",
            isFriend: false
        )
        
        // Fake Posts
        posts = [
            Post(
                id: UUID(),
                username: "val",
                timestamp: Date().addingTimeInterval(-60),
                content: "Hi🖤",
                feeling: "Satisfied",
                emoji: "😌"
            ),
            Post(
                id: UUID(),
                username: "val",
                timestamp: Date().addingTimeInterval(-300),
                content: "Just left pilates",
                feeling: "Motivated",
                emoji: "💪"
            ),
            Post(
                id: UUID(),
                username: "val",
                timestamp: Date().addingTimeInterval(-1200),
                content: "Hecka drinking tea ☕🍵",
                feeling: "Cozy",
                emoji: "☁️"
            ),
            Post(
                id: UUID(),
                username: "val",
                timestamp: Date().addingTimeInterval(-3200),
                content: "Happy Birthday Maya! 🎉",
                feeling: "Grateful",
                emoji: "🥰"
            )
        ]
    }
}

