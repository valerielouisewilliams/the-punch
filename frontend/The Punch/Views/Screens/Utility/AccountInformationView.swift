//
//  AccountInformationView.swift
//  ThePunch
//
//  Created by Valerie Williams on 4/1/26.
//

import SwiftUI

struct AccountInformationView: View {
    @EnvironmentObject private var authManager: AuthManager

    let user: User
    var onUserUpdated: ((User) -> Void)? = nil

    @State private var phoneNumber: String
    @State private var isSaving = false
    @State private var showSaved = false
    @State private var errorMessage: String?

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
                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)

                    Button {
                        Task { await saveAccountInfo() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                            }
                            Text(isSaving ? "Saving..." : "Save Phone Number")
                        }
                    }
                    .disabled(isSaving || !isPhoneNumberValid)

                    if !isPhoneNumberValid {
                        Text("Enter a valid US phone number or leave blank")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }

                    if showSaved {
                        Text("Saved")
                            .font(.footnote)
                            .foregroundColor(.green)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }

                Section("Security") {
                    NavigationLink {
                        ChangePasswordView()
                    } label: {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.secondary)
                            Text("Change Password")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .tint(Color(red: 0.95, green: 0.60, blue: 0.20))
        }
        .navigationTitle("Account Information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isPhoneNumberValid: Bool {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let digits = trimmed.filter(\.isNumber)
        return digits.count == 10 || (digits.count == 11 && digits.first == "1")
    }

    private func saveAccountInfo() async {
        guard !isSaving else { return }
        guard isPhoneNumberValid else { return }

        isSaving = true
        showSaved = false
        errorMessage = nil
        defer { isSaving = false }

        do {
            let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            let updated = try await APIService.shared.updateAccountInformation(
                phoneNumber: trimmed.isEmpty ? nil : trimmed
            )

            authManager.currentUser = updated
            onUserUpdated?(updated)
            showSaved = true
            phoneNumber = updated.phoneNumber ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
