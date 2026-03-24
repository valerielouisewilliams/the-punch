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
import GoogleSignIn

@main
struct The_PunchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var uiState = UIState()
    @StateObject private var authManager = AuthManager.shared
    @StateObject var punchState = PunchState()

    init() {
        configureFirebase()
        configureGoogleSignIn()
        NotificationManager.shared.requestPermission()
    
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                if authManager.currentUser?.username.hasPrefix("user_") == true {
                    UsernameSetupView()
                        .environmentObject(authManager)
                } else {
                    MainTabView()
                        .environmentObject(uiState)
                        .environmentObject(authManager)
                }
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

    // Required for Google Sign-In to handle the redirect URL
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

private func configureFirebase() {
    let bundleID = Bundle.main.bundleIdentifier ?? ""

    let plistName: String
    switch bundleID {
    case "com.sydneypatel.thepunch":
        plistName = "GoogleService-Info-Local"
    default:
        plistName = "GoogleService-Info"
    }

    guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
          let options = FirebaseOptions(contentsOfFile: filePath) else {
        fatalError("Could not load Firebase plist: \(plistName)")
    }

    print("Bundle ID:", bundleID)
    print("Using plist:", plistName)

    FirebaseApp.configure(options: options)
}

private func configureGoogleSignIn() {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
        fatalError("Could not find Firebase clientID")
    }
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
}
