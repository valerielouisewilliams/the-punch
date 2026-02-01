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
    
    // Form fields - SwiftUI watches these for changes
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""  // Optional: user's display name
    @State private var acceptedTerms = false
    
    // UI state
    @State private var isLoading = false        // Shows/hides loading spinner
    @State private var errorMessage = ""        // Stores error to show user
    @State private var showError = false        // Controls error alert visibility
    @State private var navigateToLogin = false  // For "Already have account" link
    
    // Body (The UI)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
                
                VStack(spacing: 22) {
                    Spacer()
                    
                    // Logo
                    Image("ThePunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                    
                    Text("ThePunch")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                    
                    // Title
                    Text("Create Account")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 16)
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        // Username field
                        RoundedTextField(placeholder: "Username", text: $username)
                            .autocapitalization(.none)  // Don't capitalize username
                        
                        // Display Name (optional - defaults to username if empty)
                        RoundedTextField(placeholder: "Display Name (optional)", text: $displayName)
                        
                        // Email field
                        RoundedTextField(placeholder: "Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)  // Show email keyboard
                        
                        // Password field
                        RoundedSecureField(placeholder: "Password", text: $password)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    // Terms/Conditions Toggle
                    HStack {
                        Button(action: {
                            acceptedTerms.toggle()
                        }) {
                            Image(systemName: acceptedTerms ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(acceptedTerms ? .orange : .gray)
                        }
                        Text("I accept the terms & privacy policy")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 8)
                    
                    // Create Account Button or Loading Spinner
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.top, 10)
                    } else {
                        OrangeButton(title: "Create Account") {
                            // Task creates async context so we can use 'await'
                            Task {
                                await register()
                            }
                        }
                        .padding(.horizontal, 50)
                        .padding(.top, 10)
                        // Disable button if validation fails
                        .disabled(!isFormValid)
                        .opacity(!isFormValid ? 0.6 : 1.0)
                    }
                    
                    // Validation hints (show what's missing)
                    if !isFormValid && (!username.isEmpty || !email.isEmpty || !password.isEmpty) {
                        VStack(spacing: 4) {
                            if username.isEmpty {
                                validationText("Username required")
                            }
                            if email.isEmpty {
                                validationText("Email required")
                            }
                            if password.isEmpty {
                                validationText("Password required")
                            } else if password.count < 6 {
                                validationText("Password must be at least 6 characters")
                            }
                            if !acceptedTerms {
                                validationText("Must accept terms & conditions")
                            }
                        }
                        .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Already have an account?
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                        
                        NavigationLink(destination: LoginView(), isActive: $navigateToLogin) {
                            EmptyView()
                        }
                        
                        Button("Log In") {
                            navigateToLogin = true
                        }
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                        .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal)
            }
            // Show error alert when registration fails
            .alert("Registration Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
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
