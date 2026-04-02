import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthManager

    var onLoggedOut: (() -> Void)? = nil
    var onProfileUpdated: ((User) -> Void)? = nil

    @State private var showLegalSheet = false
    @State private var legalPage: LegalSheetView.Page = .terms

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10)
                    .ignoresSafeArea()

                List {
                    // Profile
                    Section("Profile") {
                        if let user = auth.currentUser {
                            NavigationLink {
                                EditProfileView(user: user, onProfileUpdated: onProfileUpdated)
                            } label: {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                        }
                    }

                    // Account Information
                    Section("Account Information") {
                        if let user = auth.currentUser {
                            NavigationLink {
                                AccountInformationView(
                                    user: user,
                                    onUserUpdated: { updatedUser in
                                        auth.currentUser = updatedUser
                                        onProfileUpdated?(updatedUser)
                                    }
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                    Text("Account Information")
                                }
                            }
                        }
                    }

                    // Privacy
                    Section("Privacy") {
                        if let user = auth.currentUser {
                            NavigationLink {
                                //PrivacySettingsView(user: user)
                            } label: {
                                HStack {
                                    Label("Phone Visibility", systemImage: "lock")
                                    Spacer()
                                    Text((user.discoverableByPhone ?? false) ? "On" : "Off")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Notifications
                    Section("Notifications") {
                        NavigationLink {
                            //NotificationSettingsView()
                        } label: {
                            Label("Notification Preferences", systemImage: "bell")
                        }
                    }

                    // Support
                    Section("Support") {
                        NavigationLink {
                            FAQView()
                        } label: {
                            Label("FAQ", systemImage: "questionmark.circle")
                        }
                    }

                    // Legal
                    Section("Legal") {
                        Button {
                            legalPage = .terms
                            showLegalSheet = true
                        } label: {
                            Label("Terms & Conditions", systemImage: "doc.text")
                        }

                        Button {
                            legalPage = .privacy
                            showLegalSheet = true
                        } label: {
                            Label("Privacy Policy", systemImage: "lock.shield")
                        }
                    }

                    // Danger Zone
                    Section("Danger Zone") {
                        Button(role: .destructive) {
                            Task { await handleLogout() }
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
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
        }
    }

    private func handleLogout() async {
        auth.logout()
        onLoggedOut?()
        dismiss()
    }
}
