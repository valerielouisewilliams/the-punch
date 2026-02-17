//
//  The_PunchApp.swift
//  The Punch
//
//  Created by Valerie Williams on 9/30/25.
//

import SwiftUI
import FirebaseCore
import UIKit
import FirebaseMessaging

@main
struct The_PunchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var uiState = UIState()
    @StateObject private var authManager = AuthManager.shared
    @StateObject var punchState = PunchState()

    init() {
        FirebaseApp.configure()

        // Keep permission request (needed for remote push too)
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
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


final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Links APNs <-> FCM for iOS delivery
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications:", error.localizedDescription)
    }
}

