//
//  LoginView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct LoginView: View {
    // Single source of truth for auth state
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var googleSignIn = GoogleSignInHandler()
    @StateObject private var appleSignIn = AppleSignInHandler()

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var infoMessage = ""
    @State private var showInfo = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Spacer()
                    
                    Image("ThePunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    
                    Text("ThePunch")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))

                    // Email / Password
                    VStack(spacing: 18) {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.white.opacity(0.6)))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.6)))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 50)
                    
                    Button("Forgot password?") {
                        Task { await resetPassword() }
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .font(.footnote)
                    .disabled(isLoading || isGoogleLoading || isAppleLoading)

                    // Log In button
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        OrangeButton(title: "Log In") {
                            Task { await login() }
                        }
                        .padding(.horizontal, 50)
                        .disabled(email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    }

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.2))
                        Text("or").foregroundColor(.white.opacity(0.5)).font(.footnote)
                        Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.2))
                    }
                    .padding(.horizontal, 50)

                    // Sign in with Google
                    if isGoogleLoading || isAppleLoading {
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
                                Text("Sign in with Google")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                        .padding(.horizontal, 50)

                        SignInWithAppleButton(.signIn) { request in
                            appleSignIn.prepare(request: request)
                        } onCompletion: { result in
                            Task {
                                isAppleLoading = true
                                defer { isAppleLoading = false }
                                do {
                                    try await appleSignIn.handle(result: result)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(25)
                        .padding(.horizontal, 50)
                    }

                    NavigationLink("Don't have an account? Sign Up") {
                        CreateAccountView()
                    }
                    .foregroundColor(.white)
                    .font(.footnote)
                    
                    Spacer()
                }
            }
            .alert("Login Failed", isPresented: $showError) {
                Button("OK") { }
            } message: { Text(errorMessage) }
            .alert("Info", isPresented: $showInfo) {
                Button("OK") { }
            } message: { Text(infoMessage) }
        }
    }
    
    // Login
    func login() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)

            if let firebaseUser = Auth.auth().currentUser, !firebaseUser.isEmailVerified {
                infoMessage = "Please verify your email before continuing. Use the verification screen to resend the email if needed."
                showInfo = true
                return
            }

            // now tell backend “this Firebase user is signed in”
            try await AuthManager.shared.syncSessionWithBackend()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        // Quick connectivity sanity check
        func testAPIConnection() {
            Task {
                do {
                    appLog("Testing API connection…")
                    let response = try await APIService.shared.getPosts()
                    appLog("API Connected! Found \(response.data.count) posts")
                } catch {
                    appLog("API Connection Failed:", error.localizedDescription)
                }
            }
        }
    }
    
    // Password reset
    func resetPassword() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email first, then tap Forgot password."
            showError = true
            return
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmedEmail)
            infoMessage = "We sent a password reset email to \(trimmedEmail). Check your inbox (and spam folder)."
            showInfo = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
