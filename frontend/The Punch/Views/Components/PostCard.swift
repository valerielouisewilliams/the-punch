//
//  PostCard.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI
import Foundation

struct PostCard: View {
    let post: Post
    @EnvironmentObject var auth: AuthManager
    @StateObject private var lookup = UserLookup.shared

    private let iso = ISO8601DateFormatter()
    private let rel = RelativeDateTimeFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(Color.white).frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(lookup.username(for: post.userId) ?? provisionalUsername)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text(displayTime)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }

            Text(post.text)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(.white)

            HStack(spacing: 6) {
                Text("FEELING:").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                Text(post.feelingEmoji).font(.system(size: 13, weight: .medium, design: .monospaced)).foregroundColor(.white)
                Text(post.feelingEmoji).font(.system(size: 14))
            }
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(Color.white.opacity(0.08)).clipShape(Capsule())
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
        .task {
            // auto-load username if missing
            if lookup.username(for: post.userId) == nil {
                await lookup.loadUsername(for: post.userId, token: auth.token)
            }
        }
    }

    private var provisionalUsername: String {
        if let me = auth.currentUser, me.id == post.userId { return me.username }
        return "user\(post.userId)"
    }

    private var displayTime: String {
        if let date = ISO8601DateFormatter().date(from: post.createdAt) {
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}
