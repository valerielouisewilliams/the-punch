//
//  LoginView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

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
                        TextField("Email", text: $email)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
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
        .onAppear { testAPIConnection() }
    }

    // Login with Firebase
    func login() async {
        isLoading = true
        defer { isLoading = false }
        
        await authManager.loginWithFirebase(email: email, password: password)
    }
   
// ---------------
// OLD LOGIN LOGIC:
// ---------------
// func login() async {

//        do {
//            let response = try await APIService.shared.login(email: email, password: password)
//
//            // Single source of truth: persists token to "authToken" + user; flips isAuthenticated
//            await MainActor.run {
//                AuthManager.shared.completeLogin(
//                    user: response.data.user,
//                    token: response.data.token 
//                )
//            }
//
//            #if DEBUG
//            let saved = UserDefaults.standard.string(forKey: "authToken") ?? "<nil>"
//            print("Login OK. Saved authToken prefix:", saved.prefix(12), "…")
//            #endif
//
//        } catch let apiErr as APIError {
//            errorMessage = apiErr.localizedDescription
//            showError = true
//        } catch {
//            errorMessage = "Something went wrong. Please try again."
//            showError = true
//        }
//  }

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
