//
//  UsernameSetupView.swift
//  ThePunch
//
//  Created by Sydney Patel on 3/24/26.
//

//  shown after Google Sign-In when the user has a placeholder username.
//  collects username, display name, and T&C acceptance before entering the app.

import SwiftUI

struct UsernameSetupView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var username = ""
    @State private var displayName = ""
    @State private var phoneNumber = ""
    @State private var discoverableByPhone = true
    @State private var acceptedTerms = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showLegalSheet = false
    @State private var legalPage: LegalSheetView.Page = .terms

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                Image("ThePunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)

                Text("ThePunch")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))

                Text("Set up your profile to get started.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))

                VStack(spacing: 16) {
                    RoundedTextField(placeholder: "Username", text: $username)
                        .autocapitalization(.none)

                    RoundedTextField(placeholder: "Display Name (optional)", text: $displayName)

                    RoundedTextField(placeholder: "Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)

                    Toggle("Allow friend suggestions by phone number", isOn: $discoverableByPhone)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                // T&C toggle
                HStack(alignment: .top, spacing: 8) {
                    Button(action: { acceptedTerms.toggle() }) {
                        Image(systemName: acceptedTerms ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(acceptedTerms ? .orange : .gray)
                    }

                    HStack(spacing: 0) {
                        Text("I accept the ")
                            .foregroundColor(.white)
                        Button("Terms & Conditions") {
                            legalPage = .terms
                            showLegalSheet = true
                        }
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)

                // Validation hints
                if !isFormValid && !username.isEmpty {
                    VStack(spacing: 4) {
                        if username.count < 3 {
                            validationText("Username must be at least 3 characters")
                        }
                        if !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValidPhoneNumber(phoneNumber) {
                            validationText("Enter a valid US phone number")
                        }
                        if !acceptedTerms {
                            validationText("Must accept terms & conditions")
                        }
                    }
                    .font(.caption)
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding(.top, 10)
                } else {
                    OrangeButton(title: "Let's Go") {
                        Task { await completeSetup() }
                    }
                    .padding(.horizontal, 50)
                    .padding(.top, 10)
                    .disabled(!isFormValid)
                    .opacity(!isFormValid ? 0.6 : 1.0)
                }

                Spacer()
            }
        }
        .alert("Setup Failed", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showLegalSheet) {
            LegalSheetView(initialPage: legalPage)
        }
    }

    var isFormValid: Bool {
        username.count >= 3 && isPhoneNumberValidOrEmpty && acceptedTerms
    }

    var isPhoneNumberValidOrEmpty: Bool {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || isValidPhoneNumber(trimmed)
    }

    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let digits = phoneNumber.filter(\.isNumber)
        return digits.count == 10 || (digits.count == 11 && digits.first == "1")
    }

    func validationText(_ text: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
            Text(text)
        }
        .foregroundColor(.orange)
        .font(.caption)
    }

    func completeSetup() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let token = try await AuthManager.shared.firebaseIdToken()
            try await APIService.shared.completeProfile(
                firebaseToken: token,
                username: username.trimmingCharacters(in: .whitespaces),
                displayName: displayName.isEmpty ? username : displayName,
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                discoverableByPhone: discoverableByPhone
            )
            try await AuthManager.shared.syncSessionWithBackend()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
