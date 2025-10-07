//
//  LoginView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

/**
 The view that allows users to log in to their account.
 */
struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var navigateToFeed = false  // 👈 controls navigation

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
                        TextField("Username", text: $username)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 50)
                    
                    OrangeButton(title: "Log In") {
                        // For testing: navigate directly to FeedView
                        navigateToFeed = true
                    }
                    .padding(.horizontal, 50)
                    
                    Spacer()
                }
            }
            // Hidden navigation link that triggers programmatically
            .background(
                NavigationLink(destination: MainTabView(),
                               isActive: $navigateToFeed) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
}

