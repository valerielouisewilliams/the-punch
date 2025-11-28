//
//  PostDetailView.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/6/25.
//


import SwiftUI
import Foundation

struct PostDetailView: View {
    @Binding var post: Post
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    @State private var newCommentText = ""
    @State private var isPostingComment = false
    @State private var errorMessage: String?
    @StateObject private var authManager = AuthManager.shared
    @FocusState private var isCommentFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Post at the top
                    PostCard(post: post, context: .detail)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical)
                    
                    // Comments section
                    if isLoadingComments {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                    } else if comments.isEmpty {
                        Text("No comments yet. Be the first!")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    onDelete: { removeComment(comment) }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            
            // Error banner
            if let errorMessage = errorMessage {
                VStack {
                    HStack {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .hidesFloatingButton()
        .safeAreaInset(edge: .bottom) {
            // Comment input field
            if authManager.isAuthenticated {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        TextField("",
                                  text: $newCommentText,
                                  prompt: Text("Add a comment...")
                                    .foregroundColor(.white),
                                  axis: .vertical
                            )
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                            .focused($isCommentFieldFocused)
                            .lineLimit(1...4)
                        
                        Button(action: postComment) {
                            if isPostingComment {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                            }
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
                    }
                    .padding()
                    .background(Color(red: 0.15, green: 0.13, blue: 0.13))
                }
            }
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: .postDidUpdate)) { notif in
            guard
                let id = notif.userInfo?["id"] as? Int,
                id == post.id,
                let isLiked = notif.userInfo?["isLiked"] as? Bool,
                let likeCount = notif.userInfo?["likeCount"] as? Int
            else { return }

            post.stats.userHasLiked = isLiked
            post.stats.likeCount = likeCount
        }
        .onReceive(NotificationCenter.default.publisher(for: .commentDidCreate)) { notif in
            guard
                let postId = notif.userInfo?["postId"] as? Int,
                postId == post.id,
                let newComment = notif.userInfo?["comment"] as? Comment
            else { return }

            // Don't double-insert if it was created inside this view
            if !comments.contains(where: { $0.id == newComment.id }) {
                comments.insert(newComment, at: 0)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .commentDidDelete)) { notif in
            guard
                let postId = notif.userInfo?["postId"] as? Int,
                postId == post.id,
                let deletedId = notif.userInfo?["commentId"] as? Int
            else { return }

            comments.removeAll { $0.id == deletedId }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Comments")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        Task {
            isLoadingComments = true
            errorMessage = nil
            
            do {
                let response = try await APIService.shared.getComments(
                    postId: post.id,
                    token: authManager.token
                )
                await MainActor.run {
                    comments = response.comments
                    isLoadingComments = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load comments"
                    isLoadingComments = false
                }
                print("Failed to load comments: \(error)")
            }
        }
    }
    
    private func postComment() {
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let token = authManager.token, !trimmedText.isEmpty else { return }
        
        isPostingComment = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.createComment(
                    postId: post.id,
                    text: trimmedText,
                    token: token
                )
                
                await MainActor.run {
                    // Add user info to the new comment if not included
                    var newComment = response.comment
                    if newComment.user == nil {
                        // Create user info from current user
                        newComment = Comment(
                            id: response.comment.id,
                            postId: response.comment.postId,
                            userId: response.comment.userId,
                            text: response.comment.text,
                            createdAt: response.comment.createdAt,
                            user: PostAuthor(
                                id: authManager.currentUser?.id ?? 0,
                                username: authManager.currentUser?.username ?? "",
                                displayName: authManager.currentUser?.displayName,
                                avatarUrl: authManager.currentUser?.avatarUrl
                            )
                        )
                    }
                    
                    comments.insert(newComment, at: 0)
                    newCommentText = ""
                    isCommentFieldFocused = false
                    isPostingComment = false
                    
                    // Notify listeners
                    NotificationCenter.default.post(
                        name: .commentDidCreate,
                        object: nil,
                        userInfo: [
                            "postId": post.id,
                            "comment": newComment
                        ]
                    )

                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to post comment"
                    isPostingComment = false
                }
                print("Failed to post comment: \(error)")
            }
        }
    }
    
    private func removeComment(_ comment: Comment) {
        comments.removeAll { $0.id == comment.id }

        NotificationCenter.default.post(
            name: .commentDidDelete,
            object: nil,
            userInfo: [
                "postId": post.id,
                "commentId": comment.id
            ]
        )

    }
}
