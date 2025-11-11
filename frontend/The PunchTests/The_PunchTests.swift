//
//  The_PunchTests.swift
//  The PunchTests
//
//  Created by Valerie Williams on 9/30/25.
//

import Testing
@testable import The_Punch
import SwiftUI

struct The_PunchTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @StateObject private var auth = AuthManager.shared   // auth manager
    
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("-uiTestSettings") {
                TestableSettingsScreen()
                    .environmentObject(auth)
            } else {
                SplashScreenView()
                    .environmentObject(auth)
            }
        }
    }
    
    private struct TestableSettingsScreen: View {
        @State private var loggedOut = false

        var body: some View {
            NavigationStack {
                SettingsView(onLoggedOut: { loggedOut = true })
                    .overlay(alignment: .bottom) {
                        if loggedOut {
                            Text("logged_out_banner")
                                .padding(8)
                                .background(.thinMaterial)
                                .accessibilityIdentifier("logged_out_banner")
                        }
                    }
            }
        }
    }

}

