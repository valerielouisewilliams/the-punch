//
//  PostCard.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Avatar + Username + Timestamp
            HStack(alignment: .center) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.username.uppercased())
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("· \(relativeTime(from: post.timestamp))")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            
            // Content
            Text(post.content)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(nil)
            
            // Feeling Tag
            HStack(spacing: 6) {
                Text("FEELING:")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(post.feeling)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                Text(post.emoji)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
    }
    
    private func relativeTime(from date: Date) -> String {
        let secondsAgo = Int(Date().timeIntervalSince(date))
        if secondsAgo < 60 {
            return "\(secondsAgo) seconds ago"
        } else if secondsAgo < 3600 {
            return "\(secondsAgo / 60) minutes ago"
        } else {
            return "\(secondsAgo / 3600) hours ago"
        }
    }
}
