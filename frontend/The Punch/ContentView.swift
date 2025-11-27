import SwiftUI

/**
 The welcome screen for new users.
 */
struct WelcomeView: View {
    @EnvironmentObject var punchState: PunchState

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10) // deep brown/black background
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Logo
                VStack(spacing: 12) {
                    Image("ThePunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    
                    Text("ThePunch")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20)) // orange tone
                        .shadow(radius: 2)
                }
                
                // Subtitle
                VStack(spacing: 4) {
                    Text("welcome to the punch!")
                    Text("give updates to your friends in real time!")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 18) {
                    OrangeButton(title: "Get Started") {
                        print("Get Started tapped")
                    }
                    
                    OrangeButton(title: "Log In") {
                        print("Log In tapped")
                    }
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 80)
            }
            .onReceive(NotificationCenter.default.publisher(for: .punchTimeTriggered)) { _ in
                print("🔥 Punch Time triggered!")
                
                if let date = NotificationManager.shared.getTodayPunchTime(),
                   let id = NotificationManager.shared.getTodayPunchId() {
                    
                    punchState.isPunchTimeActive = true
                    punchState.punchTime = date
                    punchState.punchId = id
                }
            }
        }
    }
}


