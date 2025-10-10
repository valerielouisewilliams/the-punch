//
//  CreateAccountView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

/**
 The view that allows users to create accounts
 */
struct CreateAccountView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var acceptedTerms = false
    @State private var navigateToLogin = false
    
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
                    
                    // Fields
                    VStack(spacing: 16) {
                        RoundedTextField(placeholder: "Username", text: $username)
                        RoundedTextField(placeholder: "Email", text: $email)
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
                    
                    // Create Account Button
                    OrangeButton(title: "Create Account") {
                        //TODO: Connect backend
                    }
                    .padding(.horizontal, 50)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Already have an account?
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                        
                        NavigationLink(destination: LoginView(), isActive: $navigateToLogin) { EmptyView() }
                        
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
        }
    }
}
