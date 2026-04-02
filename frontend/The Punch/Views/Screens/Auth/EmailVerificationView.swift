import FirebaseAuth
import SwiftUI

struct EmailVerificationView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isRefreshing = false
    @State private var isResending = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private var currentEmail: String {
        Auth.auth().currentUser?.email ?? authManager.currentUser?.email ?? "your email"
    }

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "envelope.badge")
                    .font(.system(size: 64))
                    .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))

                Text("Verify your email")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("We sent a verification link to \(currentEmail). Please verify your email before continuing.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.3)
                } else {
                    OrangeButton(title: "I've Verified") {
                        Task { await refreshVerification() }
                    }
                    .padding(.horizontal, 50)
                }

                if isResending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.1)
                } else {
                    Button("Resend verification email") {
                        Task { await resendVerification() }
                    }
                    .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                    .font(.system(size: 15, weight: .semibold))
                }

                Button("Log out") {
                    authManager.logout()
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 8)

                Spacer()
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    func refreshVerification() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let verified = try await authManager.refreshEmailVerificationStatus()
            if !verified {
                alertTitle = "Not verified yet"
                alertMessage = "We still don't see verification on your account. Open the email link, then try again."
                showAlert = true
            }
        } catch {
            alertTitle = "Could not refresh"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    func resendVerification() async {
        isResending = true
        defer { isResending = false }

        do {
            try await authManager.sendEmailVerification()
            alertTitle = "Email sent"
            alertMessage = "Verification email sent again. Check your inbox and spam folder."
            showAlert = true
        } catch {
            alertTitle = "Could not send"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
