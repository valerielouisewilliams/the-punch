import SwiftUI

struct CreatePunchView: View {
    var onPosted: ((Post) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var feelingText: String = ""     // free-form feeling
    @State private var emojiText: String = ""       // user-chosen emoji from keyboard
    @State private var isPosting = false
    @State private var errorMessage: String?
    @State private var showEmojiPicker = false
    
    // Keep your nice suggestions
    private let feelingSuggestions = ["Chill", "Happy", "Catty", "Focused", "Proud", "Curious", "Tired"]
    private let emojiSuggestions = ["😎","🥰","🤓","😴","⚡️","✨","🔥","🧠","☁️"]
    private let maxChars = 280
    private let maxFeelingLen = 32
    
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
                    
                    // Free-form Feeling
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Feeling")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 10) {
                            TextField("Type anything (e.g., grateful, feral, inspired…)", text: $feelingText)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .onChange(of: feelingText) { _ in
                                    if feelingText.count > maxFeelingLen {
                                        feelingText = String(feelingText.prefix(maxFeelingLen))
                                    }
                                }
                        }
                        
                        // Suggestions: tap to autofill the field
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(feelingSuggestions, id: \.self) { f in
                                    Button {
                                        feelingText = f
                                    } label: {
                                        Text(f)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color.white.opacity(0.08))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)

                        HStack(spacing: 10) {
                            // “Pick Emoji” button (primary path)
                            Button {
                                showEmojiPicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    Text(emojiText.isEmpty ? "😝" : emojiText)
                                        .font(.system(size: 22, weight: .semibold))
                                        .frame(width: 56, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.08))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Text("Open Picker")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule().fill(Color.white.opacity(0.08))
                                        )
                                        .overlay(
                                            Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            
                        }
                    }
                    .sheet(isPresented: $showEmojiPicker) {
                        EmojiPicker { picked in
                            emojiText = picked
                        }
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
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // Submit
    private func submit() async {
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
        defer { Task { await MainActor.run { isPosting = false } } }
        
        // Allow either or both to be empty — backend can treat them as optional
        let finalFeeling = feelingText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalEmoji = emojiText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let response = try await APIService.shared.createPost(
                text: trimmed,
                feelingEmoji: finalEmoji,          // any emoji, or ""
                feelingName: finalFeeling,         // any text, or ""
                token: token
            )
            let created = response.data
            
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .postDidCreate,
                    object: nil,
                    userInfo: ["post": created]
                )

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

struct EmojiPicker: View {
    @Environment(\.dismiss) private var dismiss
    var onPick: (String) -> Void

    // Curate or expand as you like
    private let categories: [[String]] = [
        ["😀","😄","😊","🥰","😍","🤩","😎","🥳","😴","🤓","🫶","✨","🔥","⚡️","💫","🌈"],
        ["😡","😤","😢","😭","😮‍💨","😵‍💫","🤯","🤠","😇","🤡","👻","💀","🧠","💪","🫀","🩷"],
        ["🍕","🍔","🍟","🍜","🍣","🍪","🍩","☕️","🥤","🍸","🍷","🍺","⚽️","🏀","🎮","🎧"],
        ["🌞","🌙","⭐️","☁️","🌧","❄️","🌪","🌊","🔥","🪄","🧿","💎","🧸","🎁","📸","💡"]
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(0..<categories.count, id: \.self) { idx in
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(categories[idx], id: \.self) { e in
                                Button {
                                    onPick(e)
                                    dismiss()
                                } label: {
                                    Text(e).font(.system(size: 28))
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 12)
            }
            .navigationTitle("Choose an Emoji")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


