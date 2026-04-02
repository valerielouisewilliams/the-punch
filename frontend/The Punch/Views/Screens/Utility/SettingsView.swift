import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthManager

    /// Called after a successful logout so the parent can clear state or route to login.
    var onLoggedOut: (() -> Void)? = nil
    var onProfileUpdated: ((User) -> Void)? = nil

    @State private var showLegalSheet = false
    @State private var legalPage: LegalSheetView.Page = .terms

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

                List {

                    Section {
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
}
