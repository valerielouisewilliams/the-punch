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
    var onAuthorTap: (() -> Void)? = nil
    
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @StateObject private var authManager = AuthManager.shared
    @State private var likeInFlight = false
    @State private var showReportSheet = false
    @State private var showReportConfirmation = false
    
    @State private var isHidden = false
    @State private var selectedMentionUserId: Int?
    @StateObject private var userLookup = UserLookup.shared
    
    enum PostContext {
        case feed
        case profile
        case detail
        case search
    }
    
    init(post: Post, context: PostContext = .feed, onAuthorTap: (() -> Void)? = nil) {
        self.post = post
        self.context = context
        self.onAuthorTap = onAuthorTap
        print("PostCard init - post \(post.id): userHasLiked = \(post.stats.userHasLiked), likeCount = \(post.stats.likeCount)")
        self._isLiked = State(initialValue: post.stats.userHasLiked)
        self._likeCount = State(initialValue: post.stats.likeCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Button {
                    onAuthorTap?()
                } label: {
                    HStack(spacing: 12) {
                        Group {
                            if let avatarUrl = post.author.avatarUrl,
                               let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.author.displayNameOrUsername)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("@\(post.author.username)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if !isOwnPost {
                    Button {
                        showReportSheet = true
                    } label: {
                        Image(systemName: "flag")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                
                Text(formatDate(post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                
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
            LinkedText(
                text: post.text,
                onMentionTap: { username in
                    openMentionProfile(username: username)
                }
            )
            
            // MARK: - Song
            if let songTitle = post.songTitle,
               let songArtist = post.songArtist {
                
                Button {
                    if let urlString = post.songUrl,
                       let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        
                        // Album art (match small badge scale)
                        if let imageUrl = post.songImage,
                           let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.white.opacity(0.08)
                            }
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            Image(systemName: "music.note")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        // Text (same as feeling badge)
                        HStack(spacing: 4) {
                            Text(songTitle)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))

                            Text(songArtist)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .layoutPriority(1)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)   // ⬅️ same as feeling
                    .padding(.vertical, 4)     // ⬅️ same as feeling
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            
            // MARK: - Engagement Bar
            HStack(spacing: 24) {
                // Like Button
                Button {
                    SoundManager.shared.playSound(.like)
                    toggleLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(likeCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)
                .disabled(likeInFlight)
                .opacity(likeInFlight ? 0.6 : 1.0)
                
                // Navigate to comments
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(post.stats.commentCount)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()

                // Song + Feeling badges (bottom-right)
                HStack(spacing: 8) {
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
                    }
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
                        CommentView(
                            comment: comment,
                            onMentionTap: { username in
                                openMentionProfile(username: username)
                            }
                        )
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
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(isPresented: $showReportSheet) { reason in
                submitReport(reason: reason)
            }
            .presentationDetents([.large])
        }
        .alert("Thanks for keeping The Punch safe", isPresented: $showReportConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This Punch has been reported to our moderators. We review all reports and take action when our community guidelines are violated. Thank you for protecting our community!")
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedMentionUserId != nil },
            set: { if !$0 { selectedMentionUserId = nil } }
        )) {
            if let userId = selectedMentionUserId {
                UserProfileView(userId: userId)
            }
        }
    }
        
    private var isOwnPost: Bool {
        authManager.currentUser?.id == post.author.id
    }
    
    private func submitReport(reason: String) {
        print("Reported post \(post.id) for: \(reason)")
        isHidden = true
            NotificationCenter.default.post(
                name: .postDidDelete,
                object: nil,
                userInfo: ["id": post.id]
            )
        showReportConfirmation = true
    }
    
    private func toggleLike() {
        guard !likeInFlight else { return }
        let prevLiked = isLiked
        let prevCount = likeCount
        likeInFlight = true
        isLiked.toggle()
        likeCount = max(0, prevCount + (isLiked ? 1 : -1))
        NotificationCenter.default.post(
            name: .postDidUpdate,
            object: nil,
            userInfo: ["id": post.id, "isLiked": isLiked, "likeCount": likeCount]
        )

        // Do async work in a Task
        Task {
            do {
                let token = try await authManager.firebaseIdToken()

                if prevLiked == false {
                    _ = try await APIService.shared.likePost(postId: post.id, token: token)
                } else {
                    _ = try await APIService.shared.unlikePost(postId: post.id, token: token)
                }

                // success: nothing else needed
                await MainActor.run { likeInFlight = false }

            } catch {
                // Roll back optimistic UI on real failure
                await MainActor.run {
                    isLiked = prevLiked
                    likeCount = prevCount
                    likeInFlight = false
                }
                print("Like toggle failed:", error)
            }
        }
    }

    private func deletePost() {
        Task {
            do {
                // Get Firebase ID token on-demand (your new auth flow)
                let token = try await authManager.firebaseIdToken()

                _ = try await APIService.shared.deletePost(id: post.id, token: token)

                // Notify listeners
                NotificationCenter.default.post(
                    name: .postDidDelete,
                    object: nil,
                    userInfo: ["id": post.id]
                )
            } catch {
                print("Delete failed:", error)
            }
        }
    }

    private func openMentionProfile(username: String) {
        Task {
            let resolvedId = await userLookup.loadUserId(for: username)
            await MainActor.run {
                selectedMentionUserId = resolvedId
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

// MARK: - Comment View
struct CommentView: View {
    let comment: Comment
    var onMentionTap: ((String) -> Void)? = nil
    
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
                
                LinkedText(
                    text: comment.text,
                    font: .caption,
                    onMentionTap: onMentionTap
                )
            }
            
            Spacer()
        }
    }
}

// MARK: - Linked Text View
struct LinkedText: View {
    let text: String
    var font: Font = .body
    var onMentionTap: ((String) -> Void)? = nil
    @State private var urlToOpen: URL? = nil
    @State private var showConfirmation = false

    var body: some View {
        Text(attributedString)
            .font(font)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "mention" {
                    let usernameFromHost = url.host ?? ""
                    let usernameFromPath = url.path.replacingOccurrences(of: "/", with: "")
                    let username = usernameFromHost.isEmpty ? usernameFromPath : usernameFromHost
                    if !username.isEmpty {
                        onMentionTap?(username)
                    }
                    return .handled
                }
                urlToOpen = url
                showConfirmation = true
                return .handled
            })
            .alert(
                "Leaving The Punch",
                isPresented: $showConfirmation)
            {
                Button("Continue") {
                    if let url = urlToOpen {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You are about to navigate away from The Punch. Do you want to continue?")
            }
    }
    
    private var attributedString: AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = .white
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let nsText = text as NSString
        let matches = detector?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []
        
        for match in matches {
            guard let range = Range(match.range, in: text),
                  let url = match.url else { continue }
            let attrRange = AttributedString.Index(range.lowerBound, within: attributed)!..<AttributedString.Index(range.upperBound, within: attributed)!
            attributed[attrRange].foregroundColor = Color(red: 0.95, green: 0.60, blue: 0.20) // orange
            attributed[attrRange].underlineStyle = .single
            attributed[attrRange].link = url
        }

        if let mentionRegex = try? NSRegularExpression(pattern: "(^|[^A-Za-z0-9_])@([A-Za-z0-9_]+)") {
            let nsText = text as NSString
            let mentionMatches = mentionRegex.matches(
                in: text,
                range: NSRange(location: 0, length: nsText.length)
            )

            for match in mentionMatches {
                guard match.numberOfRanges >= 3 else { continue }
                let usernameRange = match.range(at: 2)
                let fullRange = NSRange(location: usernameRange.location - 1, length: usernameRange.length + 1)
                guard let range = Range(fullRange, in: text) else { continue }
                let attrRange = AttributedString.Index(range.lowerBound, within: attributed)!..<AttributedString.Index(range.upperBound, within: attributed)!
                let username = nsText.substring(with: usernameRange)
                attributed[attrRange].foregroundColor = Color(red: 0.95, green: 0.60, blue: 0.20)
                attributed[attrRange].link = URL(string: "mention://\(username)")
            }
        }
        return attributed
    }
}

struct ReportSheetView: View {
    @Binding var isPresented: Bool
    let onReport: (String) -> Void
    
    private let reasons = [
        "Spam",
        "Harassment or bullying",
        "Hate speech",
        "Misinformation",
        "Inappropriate content",
        "Violence or threats",
        "Other"
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
            
            VStack(spacing: 0) {
                              
                Text("Report this Punch")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Why are you reporting this Punch?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                
                VStack(spacing: 8) {
                    ForEach(reasons, id: \.self) { reason in
                        Button {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onReport(reason)
                            }
                        } label: {
                            Text(reason)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Cancel button - different color
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.95, green: 0.60, blue: 0.20).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    
                    Text("Reporting this Punch will remove it from the app immediately.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        
    }
}
