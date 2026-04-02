//
//  AccountInformationView.swift
//  ThePunch
//
//  Created by Valerie Williams on 4/1/26.
//


import SwiftUI

struct AccountInformationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthManager

    let user: User
    var onUserUpdated: ((User) -> Void)? = nil

    @State private var phoneNumber: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showRemovePhoneAlert = false

    init(user: User, onUserUpdated: ((User) -> Void)? = nil) {
        self.user = user
        self.onUserUpdated = onUserUpdated
        _phoneNumber = State(initialValue: user.phoneNumber ?? "")
    }

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10)
                .ignoresSafeArea()

            List {
                Section("Email") {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)

                        Text(user.email ?? "Unavailable")
                            .foregroundColor(.white)
                            .textSelection(.enabled)
                    }
                }

                Section("Phone Number") {
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.secondary)

                        TextField("Add phone number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(.white)
                    }

                    if !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(role: .destructive) {
                            showRemovePhoneAlert = true
                        } label: {
                            Text("Remove Phone Number")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        Task { await saveChanges() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
        }
        .navigationTitle("Account Information")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove phone number?", isPresented: $showRemovePhoneAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                phoneNumber = ""
            }
        } message: {
            Text("This will remove your phone number from your account.")
        }
    }

    private func saveChanges() async {
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            let updatedUser = try await APIService.shared.updateAccountInformation(
                phoneNumber: trimmedPhone.isEmpty ? nil : trimmedPhone
            )

            auth.currentUser = updatedUser
            onUserUpdated?(updatedUser)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
