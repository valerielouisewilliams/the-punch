//
//  LoginView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // Single source of truth for auth state
    @StateObject private var authManager = AuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
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
        }
    }
    
    // Login
    func login() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            
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
                    print("Testing API connection…")
                    let response = try await APIService.shared.getPosts()
                    print("API Connected! Found \(response.data.count) posts")
                } catch {
                    print("API Connection Failed:", error.localizedDescription)
                }
            }
        }
    }
}
