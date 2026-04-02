//
//  SearchView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI
import Contacts

/// Search for users by username and tap through to their profile.
struct SearchView: View {
    // State
    @State private var query = ""
    @State private var results: [UserProfile] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>? = nil
    @FocusState private var isFocused: Bool

    @StateObject private var auth = AuthManager.shared

    @State private var suggestedFriends: [UserProfile] = []
    @State private var isLoadingSuggestions = false
    @State private var contactsStatus = CNContactStore.authorizationStatus(for: .contacts)

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    searchBar

                    Group {
                        if trimmedQuery.isEmpty {
                            suggestedFriendsView
                        } else if isLoading {
                            loadingView
                        } else if results.isEmpty {
                            noResultsView
                        } else {
                            resultsView
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
        .onChange(of: query) { _ in
            searchTask?.cancel()

            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await performSearch()
            }
        }
        .onAppear {
            if contactsStatus == .authorized {
                Task { await loadSuggestedFriendsFromContacts() }
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))

                TextField("Search for friends", text: $query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .keyboardType(.default)
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .onSubmit {
                        Task { await performSearch() }
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var suggestedFriendsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Find Friends")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("People you may know")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.65))
            }
            .padding(.horizontal)
            
            if contactsStatus != .authorized {
                contactsPermissionPrompt
            } else if isLoadingSuggestions {
                loadingView
            } else if suggestedFriends.isEmpty {
                Text("No matches yet. Add your phone number in sign up and try again later.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal)
            }

            if !suggestedFriends.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(suggestedFriends) { user in
                            NavigationLink {
                                UserProfileView(userId: user.id)
                            } label: {
                                SuggestedFriendCard(user: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var contactsPermissionPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Allow Contacts Access")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text("We use contact phone numbers to suggest friends who already use ThePunch.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            Button("Enable Contacts") {
                Task { await requestContactsPermissionAndLoadSuggestions() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.black.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
    }

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()

            Text("Searching…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal)
    }

    private var noResultsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No results")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("Try searching by username.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(.horizontal)
    }

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(results) { user in
                    NavigationLink {
                        UserProfileView(userId: user.id)
                    } label: {
                        UserRow(user: user)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Networking

    private func performSearch() async {
        guard !trimmedQuery.isEmpty else {
            await MainActor.run {
                results = []
                isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
        }

        do {
            let response = try await APIService.shared.searchUsers(query: trimmedQuery)

            await MainActor.run {
                results = response.data
                isLoading = false
            }
        } catch {
            await MainActor.run {
                results = []
                isLoading = false
            }
            print("Search error:", error)
        }
    }
    
    private func requestContactsPermissionAndLoadSuggestions() async {
        let store = CNContactStore()
        
        do {
            let granted = try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(for: .contacts) { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            await MainActor.run {
                contactsStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            if granted {
                await loadSuggestedFriendsFromContacts()
            }
        } catch {
            print("Contacts permission error:", error)
        }
    }
    
    private func loadSuggestedFriendsFromContacts() async {
        await MainActor.run { isLoadingSuggestions = true }
        
        do {
            let phoneNumbers = try fetchDeviceContactPhoneNumbers()
            let response = try await APIService.shared.suggestedUsersByContacts(phoneNumbers: phoneNumbers)
            await MainActor.run {
                suggestedFriends = response.data
                isLoadingSuggestions = false
            }
        } catch {
            await MainActor.run {
                suggestedFriends = []
                isLoadingSuggestions = false
            }
            print("Suggested friends error:", error)
        }
    }
    
    private func fetchDeviceContactPhoneNumbers() throws -> [String] {
        let store = CNContactStore()
        let keys = [CNContactPhoneNumbersKey as CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        var numbers = Set<String>()
        try store.enumerateContacts(with: request) { contact, _ in
            for phone in contact.phoneNumbers {
                numbers.insert(phone.value.stringValue)
            }
        }
        return Array(numbers)
    }
}

// MARK: - Suggested Friend Card

private struct SuggestedFriendCard: View {
    let user: UserProfile

    var body: some View {
        VStack(spacing: 10) {
            avatarView

            VStack(spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("@\(user.username)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
        }
        .frame(width: 120)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = user.avatarUrl,
           let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.white.opacity(0.10))
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.7))
                )
        }
    }
}
