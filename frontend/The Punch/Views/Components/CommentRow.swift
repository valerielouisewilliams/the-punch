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

    @StateObject private var authManager = AuthManager.shared
    @State private var isDeleting = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
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
                    .frame(width: 24, height: 24)  // 👈 match size
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

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 4) {
                    Text(comment.user?.displayNameOrUsername ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("@\(comment.user?.username ?? "unknown")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatDate(comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Delete button for own comments
                    if comment.userId == authManager.currentUser?.id {
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
                }
                
                // Comment text
                Text(comment.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(isDeleting ? 0.5 : 1.0)
    }
    
    private func deleteComment() {
        guard let token = authManager.token else { return }
        
        isDeleting = true
        
        Task {
            do {
                _ = try await APIService.shared.deleteComment(id: comment.id, token: token)
                await MainActor.run {
                    onDelete()   // 👈 tell parent to remove it from array
                }
            } catch {
                print("Failed to delete comment: \(error)")
                await MainActor.run {
                    isDeleting = false
                }
            }
        }
    }
    
    // formatDate is perfect
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

