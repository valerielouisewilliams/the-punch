//
//  The_PunchApp.swift
//  The Punch
//
//  Created by Valerie Williams on 9/30/25.
//

import SwiftUI

@main
struct The_PunchApp: App {
    // Watch AuthManager for changes
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            // Switches when isAuthenticated changes
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
            }
        }
    }
}
