import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthManager

    /// Called after a successful logout so the parent can clear state or route to login.
    var onLoggedOut: (() -> Void)? = nil
    var onProfileUpdated: ((User) -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

                List {
                    Section {
                        Button("Test Punch in 5s") {
                            print("Testing Punch Notif")
                            NotificationManager.shared.scheduleTestNotification(seconds: 5)
                        }
                    } header : {
                        Text("Admin Only")
                    }

                    Section {
                        NavigationLink {
                            EditProfileView(user: auth.currentUser!, onProfileUpdated: onProfileUpdated)
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Profile")
                            }
                        }

                        NavigationLink {
                            //FAQView()
                        } label: {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("FAQ")
                            }
                        }
                    } header: {
                        Text("Account")
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

