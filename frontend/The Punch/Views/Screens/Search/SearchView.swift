//
//  SearchView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.

import SwiftUI

/// Search for users by username and tap through to their profile.
struct SearchView: View {
    // State
    @State private var query = ""
    @State private var results: [UserProfile] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>? = nil
    @FocusState private var isFocused: Bool

    @StateObject private var auth = AuthManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    // Top Bar + Search Field
                    HStack(spacing: 12) {
                        // Inline Search Field (no external dependency)
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.6))
                            TextField("Search for friends", text: $query)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .keyboardType(.default)
                                .foregroundColor(.white)
                                .focused($isFocused)
                                .onSubmit { Task { await performSearch() } }

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

                    // Results / States
                    Group {
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Searching…")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal)
                        } else if results.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Recent" : "No results")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                        } else {
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
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
        .onChange(of: query) { _ in
            // Debounce: cancel any in-flight search and schedule a new one
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300 ms
                await performSearch()
            }
        }
    }

    // Networking
    private func performSearch() async {
        guard !query.isEmpty else {
            results = []
            return
        }
            
        do {
            let response = try await APIService.shared.searchUsers(query: query)
            await MainActor.run {
                results = response.data
            }
        } catch {
            print("Search error:", error)
        }
    }
}
