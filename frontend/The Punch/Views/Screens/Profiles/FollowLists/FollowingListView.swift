//
//  FollowingListView.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/23/25.
//

import SwiftUI

struct FollowingListView: View {
    let userId: Int

    @ObservedObject private var authManager = AuthManager.shared

    @State private var users: [UserProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            if !isLoading && users.isEmpty && errorMessage == nil {
                Text("Not following anyone yet.")
                    .foregroundColor(.gray)
            }

            ForEach(users) { user in
                NavigationLink {
                    UserProfileView(userId: user.id)
                } label: {
                    UserRow(user: user)
                }
                .listRowBackground(Color.clear)
            }

            if isLoading && users.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Following")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFollowing()
        }
        .refreshable {
            await loadFollowing()
        }
    }

    private func loadFollowing() async {
        guard !isLoading else { return }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let token = authManager.getToken()
            let response = try await APIService.shared.getFollowingList(
                userId: userId,
                token: token
            )

            await MainActor.run {
                self.users = response.following
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                if let apiError = error as? APIError {
                    self.errorMessage = apiError.errorDescription ?? "Failed to load following."
                } else {
                    self.errorMessage = "Failed to load following."
                }
            }
            print("Following load error:", error)
        }
    }
}
