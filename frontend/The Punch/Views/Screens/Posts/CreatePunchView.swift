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
    @State private var mentionQueryTask: Task<Void, Never>? = nil
    @StateObject private var mentionAutocomplete = MentionAutocompleteViewModel()
    @StateObject private var authManager = AuthManager.shared
    
    // Spotify service variables
    @State private var showingSpotifySearch = false
    @State private var selectedTrack: SpotifyTrack?
    
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

                                    mentionQueryTask?.cancel()
                                    mentionQueryTask = Task {
                                        try? await Task.sleep(nanoseconds: 180_000_000)
                                        guard !Task.isCancelled else { return }
                                        await mentionAutocomplete.refreshSuggestions(
                                            for: content,
                                            currentUserId: authManager.currentUser?.id
                                        )
                                    }
                                }
                        }

                        if mentionAutocomplete.isVisible {
                            mentionSuggestionsList
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
                            TextField("Type anything...", text: $feelingText)
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
                        .presentationDetents([.large])
                    }
                    
                    // Spotify service
                    Button {
                        showingSpotifySearch = true
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(selectedTrack == nil ? "Add Song" : "Change Song")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                        }
                    }
                    .sheet(isPresented: $showingSpotifySearch) {
                        SpotifySearchView { track in
                            selectedTrack = track
                        }
                    }
                    
                    if let track = selectedTrack {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: track.album_image ?? "")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(.headline)

                                Text(track.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("Remove") {
                                selectedTrack = nil
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        SoundManager.shared.playSound(.punch)

        if isPosting { return }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run { errorMessage = "Say something before posting." }
            return
        }

        // Firebase token (async)
        do {
            _ = try await AuthManager.shared.firebaseIdToken()
        } catch {
            await MainActor.run { errorMessage = "You must be logged in." }
            return
        }

        await MainActor.run {
            isPosting = true
            errorMessage = nil
        }
        defer { Task { await MainActor.run { isPosting = false } } }

        let finalFeeling = feelingText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalEmoji = emojiText.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let response = try await APIService.shared.createPost(
                text: trimmed,
                feelingEmoji: finalEmoji.isEmpty ? nil : finalEmoji,
                feelingName: finalFeeling.isEmpty ? nil : finalFeeling,
                selectedTrack: selectedTrack
            )

            let created = response.data

            await MainActor.run {
                NotificationCenter.default.post(
                    name: .postDidCreate,
                    object: nil,
                    userInfo: ["post": created]
                )
                mentionAutocomplete.hide()
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

    private var mentionSuggestionsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(mentionAutocomplete.suggestions, id: \.id) { suggestion in
                    Button {
                        content = MentionTextHelper.applyMentionCompletion(
                            in: content,
                            username: suggestion.username
                        )
                        mentionAutocomplete.hide()
                    } label: {
                        Text("@\(suggestion.username)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(Color.white.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
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
        ["🤣","🥲","😚","😋","🫣","🥺","😔","😬","😶‍🌫️","😹","😈","💩","🤢","🙈","🤞","🎬"],
        ["🍕","🍔","🍟","🍜","🍣","🍪","🍩","☕️","🥤","🍸","🍷","🍺","⚽️","🏀","🎮","🎧"],
        ["🌞","🌙","⭐️","☁️","🌧","❄️","🌪","🌊","🔥","🪄","🧿","💎","🧸","🎁","📸","💡"],
        ["👀","💅","👯‍♀️","💃","🍀","💐","🚗","🧘‍♀️","🏅","🎱","🚀","🎥","🎉","🎲","❤️‍🔥","🏃‍➡️"]
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

