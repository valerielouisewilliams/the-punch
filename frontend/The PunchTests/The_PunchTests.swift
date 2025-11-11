//
//  The_PunchTests.swift
//  The PunchTests
//
//  Created by Valerie Williams on 9/30/25.
//

import Testing
@testable import The_Punch
import SwiftUI

struct SimpleScreensTests {

    @Test
    func createAccount_isValidEmail_acceptsCommonValidAddresses() {
        let v = CreateAccountView()
        #expect(v.isValidEmail("a@b.co"))
        #expect(v.isValidEmail("sydney.j.patel@gmail.com"))
        #expect(v.isValidEmail("first.m.last@sub.domain.edu"))
    }

    @Test
    func createAccount_isValidEmail_rejectsInvalidAddresses() {
        let v = CreateAccountView()
        #expect(v.isValidEmail("no-email") == false)
        #expect(v.isValidEmail("abc@") == false)
        #expect(v.isValidEmail("@domain.com") == false)
        #expect(v.isValidEmail("a@b") == false)              // none
        #expect(v.isValidEmail("a@b.c") == false)            // short
        #expect(v.isValidEmail("a b@c.com") == false)        // spaces
    }

    @Test
    func createAccount_defaultFormIsInvalid() {
        // defaults are empty/false in CreateAccountView, so form should not be valid.
        let v = CreateAccountView()
        #expect(v.isFormValid == false)
    }

    @Test
    func userProfile_keepsPassedUserId() {
        let view = UserProfileView(userId: 42)
        #expect(view.userId == 42)
    }

    // MARK: - Screening constructors

    @Test func settingsView_initializes() { _ = SettingsView() }
    @Test func splash_initializes()       { _ = SplashScreenView() }
    @Test func login_initializes()        { _ = LoginView() }
    @Test func search_initializes()       { _ = SearchView() }
    @Test func feed_initializes()         { _ = FeedView() }
    @Test func createPunch_initializes()  { _ = CreatePunchView() }
}

// MARK: - SettingsView (callback wiring)

struct SettingsViewCallbackTests {
    @Test func settingsViewStoresCallback() async throws {
        var called = false
        let view = SettingsView(onLoggedOut: { called = true })
        // The optional callback should be stored
        #expect(view.onLoggedOut != nil)  // backed by SettingsView.onLoggedOut
        // Calling it should flip the flag (pure Swift, no UI)
        await view.onLoggedOut?()
        #expect(called == true)
    }
}

// MARK: - UserProfileView (init parameter preserved)

struct UserProfileViewInitTests {
    @Test func userProfileViewKeepsUserId() async throws {
        let v = UserProfileView(userId: 42)
        #expect(v.userId == 42)  // public let userId
    }
}

// MARK: - CreateAccountView (helper)

struct CreateAccountViewEmailValidationTests {
    
    @Test func isValidEmail_acceptsCommonGoodEmails() async throws {
        let v = await CreateAccountView()
        let goods = [
            "a@b.co",
            "first.last@domain.com",
            "name+tag@sub.domain.io",
            "UPPER_lower.123@ex-ample.org"
        ]
        for e in goods {
            #expect(v.isValidEmail(e) == true)
        }
    }

    @Test func isValidEmail_rejectsClearlyBadEmails() async throws {
        let v = await CreateAccountView()
        let bads = [
            "", "nouser@", "@nodomain", "user@nodot",
            "user@domain.", "user@.com", "included @spaces.com"
        ]
        for e in bads {
            #expect(v.isValidEmail(e) == false)
        }
    }
}

// MARK: - CreatePunchView (onPosted wiring)

struct CreatePunchViewInitTests {
    @Test func createPunchViewStoresOnPosted() async throws {
        let view = CreatePunchView(onPosted: { _ in })
        #expect(view.onPosted != nil)
    }
}

// MARK: - PostDetailView (data is preserved)

struct PostDetailViewInitTests {
    private func samplePost() -> Post {
        Post(
            id: 7,
            text: "Hello, Punch!",
            feelingEmoji: "🥊",
            feelingName: "Fired up",
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:05:00Z",
            author: PostAuthor(id: 1, username: "syd", displayName: "Syd", avatarUrl: nil),
            stats: PostStats(likeCount: 0, commentCount: 0, userHasLiked: false), comments: []
        )
    }

    @Test func postDetailViewKeepsPost() async throws {
        let p = samplePost()
        let v = PostDetailView(post: p)
        #expect(v.post.id == 7)
        #expect(v.post.text == "Hello, Punch!")
        #expect(v.post.author.username == "syd")
    }
}

// MARK: - Simple smoke tests (views construct without side-effects)

struct ViewSmokeTests {
    @Test func canConstructLoginView() async throws {
        _ = await LoginView()
        #expect(true)
    }
    @Test func canConstructSplashScreenView() async throws {
        _ = await SplashScreenView()
        #expect(true)
    }
    @Test func canConstructFeedView() async throws {
        _ = await FeedView()
        #expect(true)
    }
    @Test func canConstructSearchView() async throws {
        _ = await SearchView()
        #expect(true)
    }
    @Test func canConstructSettingsView() async throws {
        _ = await SettingsView()
        #expect(true)
    }
}

// MARK: - Create Account form logic

@MainActor
struct CreateAccountValidationLogicTests {

    @Test
    func createButton_disabledWhenAnyFieldMissing() {
        // username missing
        #expect(CreateAccountView.testing_isFormValid(
            username: "", email: "a@b.co", password: "123456", acceptedTerms: true
        ) == false)

        // email invalid
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: "bad@", password: "123456", acceptedTerms: true
        ) == false)

        // password too short
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: "a@b.co", password: "123", acceptedTerms: true
        ) == false)

        // terms not accepted
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: "a@b.co", password: "123456", acceptedTerms: false
        ) == false)
    }

    @Test
    func createButton_enabledWhenAllRulesPass() {
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: "a@b.co", password: "123456", acceptedTerms: true
        ) == true)
    }
}

@MainActor
struct CreateAccountMoreValidationTests {

    // Boundary on password length
    @Test
    func passwordTooShort_isRejected() {
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: "a@b.co", password: "12345", acceptedTerms: true
        ) == false)  // 5 chars
    }

    @Test
    func passwordMinLength_isAccepted() {
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: "a@b.co", password: "123456", acceptedTerms: true
        ) == true)   // 6 chars
    }

    // Terms toggle
    @Test
    func termsMustBeAccepted() {
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: "a@b.co", password: "123456", acceptedTerms: false
        ) == false)
    }

    // Email formatting edge cases (keep if you like current behavior)
    @Test
    func emailWithSpaces_isRejected() {
        #expect(CreateAccountView.testing_isFormValid(
            username: "syd", email: " a@b.co ", password: "123456", acceptedTerms: true
        ) == false)
    }

    @Test
    func emailUppercase_isAccepted() {
        #expect(CreateAccountView.testing_isFormValid(
            username: "SYD", email: "SYD@EXAMPLE.COM", password: "123456", acceptedTerms: true
        ) == true)
    }

    // Quick sanity: default view has invalid form
    @Test
    func defaultView_isInvalid() {
        let v = CreateAccountView()
        #expect(v.isFormValid == false)
    }
}

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
    
    // can delete this later....
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

