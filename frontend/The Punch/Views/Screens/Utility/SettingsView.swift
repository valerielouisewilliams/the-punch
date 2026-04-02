import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthManager

    /// Called after a successful logout so the parent can clear state or route to login.
    var onLoggedOut: (() -> Void)? = nil
    var onProfileUpdated: ((User) -> Void)? = nil

    @State private var showLegalSheet = false
    @State private var legalPage: LegalSheetView.Page = .terms
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

                List {

                    Section {
                        if let user = auth.currentUser {
                            NavigationLink {
                                AccountInformationView(
                                    user: user,
                                    onUserUpdated: { updated in
                                        onProfileUpdated?(updated)
                                    }
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                    Text("Account Information")
                                }
                            }
                        }

                        if let user = auth.currentUser {
                            NavigationLink {
                                EditProfileView(user: user, onProfileUpdated: onProfileUpdated)
                            } label: {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit Profile")
                                }
                            }
                        }

                        NavigationLink {
                            FAQView()
                        } label: {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("FAQ")
                            }
                        }
                    } header: {
                        Text("Account")
                    }

                    // Legal Section
                    Section {
                        Button {
                            legalPage = .terms
                            showLegalSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Terms & Conditions")
                            }
                        }

                        Button {
                            legalPage = .privacy
                            showLegalSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "lock.shield")
                                Text("Privacy Policy")
                            }
                        }
                    } header: {
                        Text("Legal")
                    }

                    Section {
                        Button(role: .destructive) {
                            showDeleteAccountAlert = true
                        } label: {
                            HStack {
                                if isDeletingAccount {
                                    ProgressView()
                                }
                                Image(systemName: "trash")
                                Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                            }
                        }
                        .disabled(isDeletingAccount)

                        Button(role: .destructive) {
                            Task { await handleLogout() }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                            }
                        }
                    } header: {
                        Text("Danger Zone")
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showLegalSheet) {
                LegalSheetView(initialPage: legalPage)
            }
            .alert("Delete account permanently?", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task { await handleDeleteAccount() }
                }
            } message: {
                Text("This action permanently deactivates your account and removes your profile data. This cannot be undone.")
            }
        }
    }

    private func handleLogout() async {
        await MainActor.run { } // keep on main for UI updates after
        do {
            auth.logout()
            onLoggedOut?()
            dismiss()
        } catch {
            auth.logout()
            onLoggedOut?()
            dismiss()
        }
    }

    private func handleDeleteAccount() async {
        errorMessage = nil
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            _ = try await APIService.shared.deleteMyAccount()
            if let currentFirebaseUser = Auth.auth().currentUser {
                do {
                    try await deleteFirebaseUser(currentFirebaseUser)
                } catch {
                    print("Firebase account deletion skipped:", error.localizedDescription)
                }
            }
            auth.logout()
            onLoggedOut?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteFirebaseUser(_ user: FirebaseAuth.User) async throws {
        try await withCheckedThrowingContinuation { continuation in
            user.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
