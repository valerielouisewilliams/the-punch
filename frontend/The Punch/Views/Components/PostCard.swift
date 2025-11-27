//
//  PostCard.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/5/25.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    let context: PostContext
    
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @StateObject private var authManager = AuthManager.shared
    @State private var likeInFlight = false // for idempotency
    
    enum PostContext {
        case feed
        case profile
        case detail
        case search
    }
    
    init(post: Post, context: PostContext = .feed) {
        self.post = post
        self.context = context
        print("PostCard init - post \(post.id): userHasLiked = \(post.stats.userHasLiked), likeCount = \(post.stats.likeCount)") //debug
        self._isLiked = State(initialValue: post.stats.userHasLiked)
        self._likeCount = State(initialValue: post.stats.likeCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Avatar
                Group {
                    if let avatarUrl = post.author.avatarUrl,
                       let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(post.author.displayNameOrUsername.prefix(1).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }

                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.displayNameOrUsername)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("@\(post.author.username)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                }
                
                Spacer()
                
               

                // Time
                Text(formatDate(post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                
                // Options Menu (for own posts)
                if isOwnPost && context == .profile {
                    Button(role: .destructive) {
                        deletePost()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption.bold())
                    }
                    
                }
            }
            
            // MARK: - Content
            Text(post.text)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            // MARK: - Engagement Bar
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
                
                // Navigate to comments
                NavigationLink(destination: PostDetailView(post: post)
                                                .toolbar(.hidden, for: .tabBar)
                                                .navigationBarHidden(false))
                {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(post.stats.commentCount)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // FEELING BADGE (bottom-right corner)
                if let emoji = post.feelingEmoji, let name = post.feelingName {
                    HStack(spacing: 6) {
                        Text("Feeling:")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(name.capitalized)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                        Text(emoji)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .trailing) // 🔥 replaces Spacer + fixes hit-test
                }

            }
            .font(.footnote)
            
            // MARK: - Comments Preview (for detail view)
            if context == .detail, let comments = post.comments {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                if comments.isEmpty {
                    Text("No comments yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    ForEach(comments.prefix(3)) { comment in
                        CommentView(comment: comment)
                            .padding(.vertical, 4)
                    }
                    
                    if comments.count > 3 {
                        Text("View all \(comments.count) comments")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.15, green: 0.13, blue: 0.13))
        .cornerRadius(12)
        .contentShape(Rectangle())

    }
        
    private var isOwnPost: Bool {
        authManager.currentUser?.id == post.author.id
    }
    
    // Actions
//    private func toggleLike() {
//        Task {
//            guard let token = authManager.token else { return }
//            
//            // Save for rollback
//            let prevLiked = isLiked
//            let prevCount = likeCount
//            
//            // Optimistic update
//            isLiked.toggle()
//            likeCount += isLiked ? 1 : -1
//            
//            do {
//                if isLiked {
//                    _ = try await APIService.shared.likePost(postId: post.id, token: token)
//                } else {
//                    _ = try await APIService.shared.unlikePost(postId: post.id, token: token)
//                }
//            } catch {
//                // Rollback on error
//                await MainActor.run {
//                    isLiked = prevLiked
//                    likeCount = prevCount
//                }
//                print("Like toggle failed: \(error)")
//            }
//        }
//    }
    
    @MainActor
    private func toggleLike() {
      // 0) Probes
      print("toggleLike() tapped")

      // 1) Guards
      guard let token = authManager.token else {
        print("No token; bailing.")
        return
      }
//      guard !likeInFlight else {
//        print("Like already in flight; ignoring tap.")
//        return
//      }

      // 2) Mark in-flight & snapshot
      likeInFlight = true
      let prevLiked = isLiked
      let prevCount = likeCount

      // 3) Optimistic UI
      isLiked.toggle()
      likeCount = max(0, prevCount + (isLiked ? 1 : -1))
    
      // 4) Broadcast a notif
      NotificationCenter.default.post(
            name: .postDidUpdate,
            object: nil,
            userInfo: ["id": post.id, "isLiked": isLiked, "likeCount": likeCount]
        )


      // 5) Kick off network work
      Task {
        defer {
          Task { @MainActor in
            likeInFlight = false
          }
        }

        do {
          if prevLiked == false {
            _ = try await APIService.shared.likePost(postId: post.id, token: token)
          } else {
            _ = try await APIService.shared.unlikePost(postId: post.id, token: token)
          }
        } catch {
          let msg = (error as NSError).localizedDescription.lowercased()
          let alreadyLiked  = msg.contains("already liked")
          let notLiked      = msg.contains("not liked") || msg.contains("already unliked")

          // Treat idempotent server states as success
          if (isLiked && alreadyLiked) || (!isLiked && notLiked) {
            print("Idempotent server state; keeping optimistic UI.")
            return
          }

          // Real failure — rollback on main
          await MainActor.run {
            isLiked = prevLiked
            likeCount = prevCount
          }
          print("Like toggle failed:", error)
        }
      }
    }

    
    private func deletePost() {
        Task {
            guard let token = authManager.token else { return }
            
            do {
                _ = try await APIService.shared.deletePost(id: post.id, token: token)
                // Post will be removed from list by parent view
            } catch {
                print("Delete failed: \(error)")
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                // Today - show time
                displayFormatter.dateFormat = "h:mm a"
            } else if calendar.isDateInYesterday(date) {
                // Yesterday
                return "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo < 7 {
                // Within a week
                return "\(daysAgo)d ago"
            } else {
                // Older
                displayFormatter.dateStyle = .medium
                displayFormatter.timeStyle = .none
            }
            
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Comment View (if in same file)
struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
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

            
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.user?.displayNameOrUsername ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(comment.text)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview Provider
struct PostCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PostCard(
                post: Post(
                    id: 1,
                    text: "Just finished my workout! Feeling great 💪",
                    feelingEmoji: "😊",
                    feelingName: "happy",
                    createdAt: "2025-01-15T10:30:00.000Z",
                    updatedAt: "2025-01-15T10:30:00.000Z",
                    author: PostAuthor(
                        id: 1,
                        username: "johndoe",
                        displayName: "John Doe",
                        avatarUrl: nil
                    ),
                    stats: PostStats(
                        likeCount: 5,
                        commentCount: 2,
                        userHasLiked: false
                    ),
                    comments: nil
                ),
                context: .feed
            )
        }
        .padding()
        .background(Color.black)
    }
}
