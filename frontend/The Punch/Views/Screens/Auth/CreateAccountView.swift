//
//  CreateAccountView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

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
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
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
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
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
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                        
                        NavigationLink(destination: LoginView(), isActive: $navigateToLogin) {
                            EmptyView()
                        }
                        
                        Button("Log In") {
                            navigateToLogin = true
                        }
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
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
        print("📝 Starting registration for: \(username)")
        
        // Step 1: Show loading state
        isLoading = true
        
        // Step 2: Call the API
        do {
            // 'await' pauses here until backend responds
            // Could take 0.5-3 seconds depending on:
            // - Network speed
            // - Password hashing (bcrypt takes time on purpose for security)
            let response = try await APIService.shared.register(
                username: username.trimmingCharacters(in: .whitespaces),  // Remove spaces
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),  // Lowercase email
                password: password,
                displayName: displayName.isEmpty ? username : displayName  // Use username if displayName empty
            )
            
            // Step 3: Registration succeeded!
            print("Registration successful!")
            print("User ID: \(response.data.user.id)")
            print("Username: \(response.data.user.username)")
            print("Token received: \(response.data.token.prefix(20))...")
            
            // Step 4: Save token and user data
            // This automatically logs the user in!
            authManager.saveToken(response.data.token)
            authManager.currentUser = response.data.user
            
            // Step 5: Navigation happens automatically
            // When saveToken() is called:
            // - isAuthenticated changes to true
            // - Your App.swift detects this change (reactive programming!)
            // - SwiftUI automatically shows MainTabView
            // - User is now logged in and can create posts!
            
            print("User logged in, navigating to feed...")
            
        } catch let error as APIError {
            // Step 6: Handle API-specific errors
            print("Registration failed: \(error)")
            
            // Provide user-friendly error messages
            switch error {
            case .httpError(409):
                // 409 Conflict means email already exists
                errorMessage = "An account with this email already exists. Please login instead."
            case .httpError(400):
                // 400 Bad Request means invalid input
                errorMessage = "Invalid information provided. Please check your inputs."
            case .httpError(let code):
                // Other HTTP errors
                errorMessage = "Registration failed (Error \(code)). Please try again."
            case .decodingError:
                // Response format doesn't match expected format
                errorMessage = "Something went wrong. Please try again later."
            default:
                errorMessage = error.localizedDescription
            }
            
            showError = true
            
        } catch {
            // Step 7: Handle unexpected errors
            print("Unexpected error: \(error)")
            errorMessage = "Something went wrong. Please try again."
            showError = true
        }
        
        // Step 8: Hide loading spinner
        isLoading = false
    }
}
