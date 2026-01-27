//
//  The_PunchApp.swift
//  The Punch
//
//  Created by Valerie Williams on 9/30/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics

@main
struct The_PunchApp: App {
    // For UI state changes like toggling the floating post button
    @StateObject private var uiState = UIState()
    
    // Watch AuthManager for changes
    @StateObject private var authManager = AuthManager.shared
    
    // Notification System
    @StateObject var punchState = PunchState()
    
    init() {
        FirebaseApp.configure()
        Analytics.logEvent("debug_connection_test", parameters: nil)

        NotificationManager.shared.requestPermission()
        NotificationManager.shared.scheduleTodayPunch()
    }
    
    var body: some Scene {
        WindowGroup {
            // Switches when isAuthenticated changes
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(uiState)
                    .environmentObject(authManager)
            } else {
                LoginView()
            }
        }
    }
}
