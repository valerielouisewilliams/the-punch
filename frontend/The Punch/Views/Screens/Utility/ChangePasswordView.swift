import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {
            Section("Current Password") {
                SecureField("Enter current password", text: $currentPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("New Password") {
                SecureField("Enter new password", text: $newPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Confirm new password", text: $confirmNewPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            if let successMessage {
                Section {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.footnote)
                }
            }

            Section {
                Button {
                    Task { await updatePassword() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSaving ? "Updating..." : "Update Password")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea())
        .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
    }

    private func updatePassword() async {
        errorMessage = nil
        successMessage = nil

        let trimmedCurrent = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmNewPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCurrent.isEmpty, !trimmedNew.isEmpty, !trimmedConfirm.isEmpty else {
            errorMessage = "Please fill in all password fields."
            return
        }

        guard trimmedNew == trimmedConfirm else {
            errorMessage = "New passwords do not match."
            return
        }

        guard trimmedNew.count >= 6 else {
            errorMessage = "New password must be at least 6 characters."
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "You are not signed in."
            return
        }

        guard let email = user.email else {
            errorMessage = "Could not verify your account email."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: trimmedCurrent)
            try await reauthenticate(user: user, with: credential)
            try await applyPasswordUpdate(user: user, to: trimmedNew)

            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            successMessage = "Password updated successfully."

            try? await Task.sleep(nanoseconds: 900_000_000)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reauthenticate(user: FirebaseAuth.User, with credential: AuthCredential) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func applyPasswordUpdate(user: FirebaseAuth.User, to newPassword: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.updatePassword(to: newPassword) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
