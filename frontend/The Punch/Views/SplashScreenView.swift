//
//  SplashScreenView.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

/**
 Splash screen that contains the logo.
 */
struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity = 0.0
    
    var body: some View {
        if isActive {
            LoginView()
        } else {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
                
                VStack {
                    Image("ThePunchLogo") 
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 1.0)) {
                                logoOpacity = 1.0
                                logoScale = 1.0
                            }
                        }
                }
            }
            .onAppear {
                // Wait before loading to simulate an API call (for our demo; this will be removed once
                // the backend is properly connected.)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

