//
//  CreateAccountView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI
import FirebaseAuth

/**
The view that allows users to create accounts.
*/
struct CreateAccountView: View {
    // State Variables
    
    // Connect to AuthManager to handle authentication
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var googleSignIn = GoogleSignInHandler()

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""  // Optional: user's display name
    @State private var acceptedTerms = false

    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var navigateToLogin = false

    @State private var showLegalSheet = false
    @State private var legalPage: LegalSheetView.Page = .terms
    
    // Body (The UI)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {

                        Image("ThePunchLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding(.top, 40)

                        Text("ThePunch")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))

                        Text("Create Account")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 8)

                        // Input Fields
                        VStack(spacing: 16) {
                            RoundedTextField(placeholder: "Username", text: $username)
                                .autocapitalization(.none)
                            RoundedTextField(placeholder: "Display Name (optional)", text: $displayName)
                            RoundedTextField(placeholder: "Email", text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            RoundedSecureField(placeholder: "Password", text: $password)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 10)

                        // Terms toggle
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

                        // Create Account button
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding(.top, 10)
                        } else {
                            OrangeButton(title: "Create Account") {
                                Task { await register() }
                            }
                            .padding(.horizontal, 50)
                            .padding(.top, 10)
                            .disabled(!isFormValid)
                            .opacity(!isFormValid ? 0.6 : 1.0)
                        }

                        // Validation hints
                        if !isFormValid && (!username.isEmpty || !email.isEmpty || !password.isEmpty) {
                            VStack(spacing: 4) {
                                if username.isEmpty { validationText("Username required") }
                                if email.isEmpty { validationText("Email required") }
                                if password.isEmpty { validationText("Password required") }
                                else if password.count < 6 { validationText("Password must be at least 6 characters") }
                                if !acceptedTerms { validationText("Must accept terms & conditions") }
                            }
                            .font(.caption)
                        }

                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.2))
                            Text("or").foregroundColor(.white.opacity(0.5)).font(.footnote)
                            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.2))
                        }
                        .padding(.horizontal, 50)

                        // Sign up with Google
                        if isGoogleLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        } else {
                            Button {
                                Task {
                                    isGoogleLoading = true
                                    defer { isGoogleLoading = false }
                                    do {
                                        try await googleSignIn.signIn()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image("google_logo")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Sign up with Google")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.75))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                            }
                            .padding(.horizontal, 50)
                        }

                        // Already have an account?
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))

                            NavigationLink(destination: LoginView(), isActive: $navigateToLogin) {
                                EmptyView()
                            }

                            Button("Log In") { navigateToLogin = true }
                                .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.bottom, 30)

                    } // end VStack
                } // end ScrollView
            }
            // Show error alert when registration fails
            .alert("Registration Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showLegalSheet) {
                LegalSheetView(initialPage: legalPage)
            }
        }
    }
    
    // Validation
    
    /**
     Check if form is valid and ready to submit.
     
     REQUIREMENTS:
     - Username not empty
     - Email not empty and valid format
     - Password at least 6 characters
     - Terms accepted
     */
    var isFormValid: Bool {
        return !username.isEmpty &&
        !email.isEmpty &&
        isValidEmail(email) &&
        password.count >= 6 &&
        acceptedTerms
    }
    
    /**
     Validate email format.
     Uses regex to check if email looks valid.
     */
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /**
     Helper to show validation error text.
     */
    func validationText(_ text: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
            Text(text)
        }
        .foregroundColor(.orange)
        .font(.caption)
    }
    
    // Registration Function (The Backend Connection!)
    
    /**
     Handle account registration with backend.
     */
    func register() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // You still want username/displayName in *your* DB, so send it to backend
            let token = try await AuthManager.shared.firebaseIdToken()
            
            try await APIService.shared.completeProfile(
                firebaseToken: token,
                username: username.trimmingCharacters(in: .whitespaces),
                displayName: displayName.isEmpty ? username : displayName
            )
            
            // then pull /me (or have completeProfile return the user)
            try await AuthManager.shared.syncSessionWithBackend()
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
