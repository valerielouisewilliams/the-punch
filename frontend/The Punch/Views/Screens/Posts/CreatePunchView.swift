//
//  CreatePunchView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/19/25.
//

import SwiftUI

// A small notification to observe in FeedView to refresh after posting
extension Notification.Name {
    static let postDidCreate = Notification.Name("postDidCreate")
}

struct CreatePunchView: View {
    /// Called after a successful post
    var onPosted: ((Post) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var selectedFeeling: String = "Chill"
    @State private var emoji: String = "😎"
    @State private var isPosting = false
    @State private var errorMessage: String?
    
    private let feelings = ["Chill", "Happy", "Catty", "Focused", "Proud", "Curious", "Tired"]
    private let maxChars = 280
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text("Create Punch")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    // Content editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What’s up?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            TextEditor(text: $content)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.white)
                                .padding(12)
                                .frame(minHeight: 120)
                                .font(.system(size: 15, weight: .regular))
                                .onChange(of: content) { _ in
                                    if content.count > maxChars {
                                        content = String(content.prefix(maxChars))
                                    }
                                }
                        }
                        
                        HStack {
                            Spacer()
                            Text("\(max(0, maxChars - content.count))")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    // Feeling chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Feeling")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(feelings, id: \.self) { f in
                                    Button {
                                        selectedFeeling = f
                                    } label: {
                                        Text(f)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(f == selectedFeeling
                                                          ? Color(red: 0.95, green: 0.60, blue: 0.20).opacity(0.25)
                                                          : Color.white.opacity(0.08))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(f == selectedFeeling
                                                            ? Color(red: 0.95, green: 0.60, blue: 0.20)
                                                            : .clear, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Emoji quick picks
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 10) {
                            ForEach(["😎","🥰","🤓","😴","⚡️","✨","🔥","🧠","☁️"], id: \.self) { e in
                                Button {
                                    emoji = e
                                } label: {
                                    Text(e)
                                        .font(.system(size: 24))
                                        .padding(6)
                                        .background(
                                            Circle()
                                                .fill(e == emoji ? Color.white.opacity(0.15) : .clear)
                                        )
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer(minLength: 12)
                    
                    // Post button
                    Button {
                        Task { await submit() }
                    } label: {
                        ZStack {
                            Text(isPosting ? "Posting…" : "Post Punch")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.95, green: 0.60, blue: 0.20))
                                .clipShape(Capsule())
                            
                            if isPosting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                        }
                    }
                    .disabled(isPosting || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // Submit
    private func submit() async {
        // Prevent double taps
        if isPosting { return }
        
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Say something before posting."
            return
        }
        guard let token = AuthManager.shared.getToken(), !token.isEmpty else {
            errorMessage = "You must be logged in."
            return
        }
        
        await MainActor.run {
            isPosting = true
            errorMessage = nil
        }
        defer {
            Task { await MainActor.run { isPosting = false } }
        }
        
        do {
            let response = try await APIService.shared.createPost(
                text: trimmed,
                feelingEmoji: emoji,            // 😎 etc. -> feeling_emoji
                feelingName: selectedFeeling,   // "Chill"  -> feeling_name
                token: token
            )
            
            let created = response.data
            
            await MainActor.run {
                NotificationCenter.default.post(name: .postDidCreate, object: created)
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription.isEmpty
                ? "Failed to create post. Please try again."
                : error.localizedDescription
            }
        }
    }
    
}
