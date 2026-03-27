//
//  CommentRow.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/6/25.
//

import SwiftUI
import Foundation

struct CommentRow: View {
    let comment: Comment
    let onDelete: () -> Void
    var onAuthorTap: (() -> Void)? = nil
    var onMentionTap: ((String) -> Void)? = nil

    @State private var isDeleting = false
    @ObservedObject private var authManager = AuthManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            authorAvatar

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    authorButton

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(formatDate(comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    if comment.userId == authManager.currentUser?.id {
                        deleteButton
                    }
                }

                LinkedText(text: comment.text, font: .body, onMentionTap: onMentionTap)
            }
        }
        .opacity(isDeleting ? 0.5 : 1.0)
    }

    private var authorAvatar: some View {
        Group {
            if let avatarUrl = comment.user?.avatarUrl,
               let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(comment.user?.displayNameOrUsername.prefix(1).uppercased() ?? "?")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
        }
        .onTapGesture {
            onAuthorTap?()
        }
    }

    private var authorButton: some View {
        Button {
            onAuthorTap?()
        } label: {
            HStack(spacing: 4) {
                Text(comment.user?.displayNameOrUsername ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("@\(comment.user?.username ?? "unknown")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button(action: deleteComment) {
            if isDeleting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .disabled(isDeleting)
    }
    
    private func deleteComment() {
        isDeleting = true

        Task {
            do {
                let token = try await AuthManager.shared.firebaseIdToken()
                _ = try await APIService.shared.deleteComment(id: comment.id, token: token)

                await MainActor.run {
                    onDelete()
                }
            } catch {
                print("Failed to delete comment: \(error)")
                await MainActor.run {
                    isDeleting = false
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
            
            if let days = components.day, days > 0 {
                return "\(days)d"
            } else if let hours = components.hour, hours > 0 {
                return "\(hours)h"
            } else if let minutes = components.minute, minutes > 0 {
                return "\(minutes)m"
            } else {
                return "now"
            }
        }
        
        return dateString
    }
}
