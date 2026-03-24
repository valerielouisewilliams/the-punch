//
//  LegalSheetView.swift
//  ThePunch
//
//  Created by Sydney Patel on 3/24/26.
//

import SwiftUI

/// Reusable sheet that shows Terms & Conditions and Privacy Policy
/// with a segmented picker to switch between them.
/// Used from both CreateAccountView and SettingsView.
struct LegalSheetView: View {

    enum Page: String, CaseIterable {
        case terms   = "Terms & Conditions"
        case privacy = "Privacy Policy"
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage: Page

    init(initialPage: Page = .terms) {
        _selectedPage = State(initialValue: initialPage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("", selection: $selectedPage) {
                        ForEach(Page.allCases, id: \.self) { page in
                            Text(page.rawValue).tag(page)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()
                        .background(Color.white.opacity(0.1))

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            switch selectedPage {
                            case .terms:   TermsContent()
                            case .privacy: PrivacyContent()
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(selectedPage.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Shared helpers

private func sectionHeader(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
        .padding(.top, 8)
}

private func subHeader(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(.white)
        .padding(.top, 4)
}

private func bodyText(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 14))
        .foregroundColor(Color.white.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
}

private func bulletText(_ text: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
        Text("•").foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Color.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Terms Content

private struct TermsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            bodyText("Effective Date: March 20, 2026")
                .italic()

            sectionHeader("1. Acceptance of Terms")
            bodyText("By downloading, installing, or using The Punch mobile application (\"App\"), you agree to be bound by these Terms and Conditions (\"Terms\"). If you do not agree to these Terms, do not use the App.")
            bodyText("We reserve the right to update or modify these Terms at any time. Continued use of the App after changes are posted constitutes your acceptance of the revised Terms. We will notify users of material changes through the App or via email.")

            sectionHeader("2. Eligibility")
            bodyText("You must be at least 18 years old to use The Punch. By using the App, you represent and warrant that you are at least 18 years old and have the legal capacity to enter into a binding agreement.")
            bodyText("The Punch does not knowingly allow access to users under the age of 18. If we become aware that a user is under 18, we will promptly delete their account.")

            sectionHeader("3. User Accounts")
            bodyText("To access certain features of the App, you must register for an account. You agree to:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("Provide accurate, current, and complete information during registration.")
                bulletText("Keep your password confidential and not share it with anyone.")
                bulletText("Notify us immediately of any unauthorized use of your account.")
                bulletText("Take full responsibility for all activity that occurs under your account.")
            }
            bodyText("We reserve the right to suspend or terminate accounts at our sole discretion, including for violations of these Terms, without prior notice or liability.")

            sectionHeader("4. User-Generated Content")
            subHeader("4.1 Ownership and License")
            bodyText("You retain ownership of any content you post, upload, or share through the App (\"User Content\"). By posting User Content, you grant The Punch a non-exclusive, royalty-free, worldwide, sublicensable license to use, reproduce, display, and distribute your content solely for the purpose of operating and improving the App. We do not guarantee that any User Content will be viewed by other users.")

            subHeader("4.2 Your Responsibility")
            bodyText("You are solely responsible for your User Content. You represent and warrant that:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("You own or have the rights to post the content.")
                bulletText("Your content does not infringe any third-party intellectual property, privacy, or other rights.")
                bulletText("Your content complies with all applicable laws.")
            }

            subHeader("4.3 Prohibited Content")
            bodyText("You may not post content that:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("Is hateful, discriminatory, or harasses any individual or group.")
                bulletText("Is sexually explicit, obscene, or pornographic.")
                bulletText("Promotes or glorifies violence, self-harm, or illegal activity.")
                bulletText("Contains another person's private information without their consent (\"doxxing\").")
                bulletText("Is spam, misleading, or constitutes unauthorized advertising.")
                bulletText("Impersonates any person or entity.")
            }

            sectionHeader("5. Prohibited Conduct")
            bodyText("In addition to prohibited content, you agree not to:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("Use the App for any unlawful purpose.")
                bulletText("Attempt to gain unauthorized access to any part of the App or its systems.")
                bulletText("Scrape, crawl, or use automated tools to extract data from the App.")
                bulletText("Interfere with or disrupt the integrity or performance of the App.")
                bulletText("Reverse engineer, decompile, or disassemble any part of the App.")
                bulletText("Create multiple accounts to evade a ban or suspension.")
                bulletText("Harass, threaten, or intimidate other users.")
                bulletText("Attempt to bypass or evade content moderation, account restrictions, or bans.")
                bulletText("Abuse reporting systems or submit false or malicious reports.")
            }

            sectionHeader("6. Reporting and Moderation")
            bodyText("We are committed to maintaining a safe and respectful community. The Punch provides a reporting feature that allows users to flag content they believe violates these Terms. Reports submitted by users are reviewed by our moderation team, and we reserve the right to remove any content and/or suspend any account that violates these Terms.")
            bodyText("Moderation decisions are made at our sole discretion. We are not obligated to remove content or take action in response to every report, nor to provide explanations for moderation actions.")

            sectionHeader("7. Intellectual Property")
            bodyText("All content, features, and functionality of the App — including but not limited to the The Punch name, logo, design, code, and graphics — are the exclusive property of The Punch and its licensors and are protected by applicable intellectual property laws.")
            bodyText("You may not copy, reproduce, modify, distribute, or create derivative works of any part of the App without our prior written consent.")

            sectionHeader("8. Privacy")
            bodyText("Your use of the App is also governed by our Privacy Policy, which is incorporated into these Terms by reference. By using the App, you consent to the collection and use of your information as described in the Privacy Policy.")
            bodyText("We collect data such as account information, content you post, and usage data in order to operate and improve the App. We do not sell your personal information to third parties.")

            sectionHeader("9. Third-Party Services")
            bodyText("The App may integrate with or link to third-party services (such as Firebase). We are not responsible for the practices, content, or availability of any third-party services. Your use of third-party services is subject to their respective terms and privacy policies.")

            sectionHeader("10. Disclaimers")
            bodyText("THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.")
            bodyText("We do not warrant that the App will be uninterrupted, error-free, or free of viruses or other harmful components. We do not guarantee that the App will always be available or that access will be uninterrupted. We do not warrant the accuracy, completeness, or reliability of any User Content posted by other users. User-generated content and interactions (including likes and comments) do not reflect the views or endorsements of The Punch.")

            sectionHeader("11. Limitation of Liability")
            bodyText("TO THE FULLEST EXTENT PERMITTED BY LAW, THE PUNCH AND ITS OWNERS, OFFICERS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO YOUR USE OF THE APP, INCLUDING DAMAGES FOR LOST PROFITS, DATA, OR GOODWILL.")
            bodyText("In no event shall our total liability to you exceed the greater of (a) the amount you paid to use the App in the twelve months preceding the claim, or (b) $100 USD.")

            sectionHeader("12. Indemnification")
            bodyText("You agree to indemnify, defend, and hold harmless The Punch and its owners, affiliates, officers, and employees from and against any claims, liabilities, damages, losses, and expenses (including reasonable attorneys' fees) arising out of or related to: (a) your use of the App; (b) your User Content; or (c) your violation of these Terms.")

            sectionHeader("13. Termination")
            bodyText("We may suspend or terminate your account and access to the App at any time, for any reason, with or without notice, including for violations of these Terms. You may also delete your account at any time through the App settings.")
            bodyText("Upon termination, your right to use the App will immediately cease. Sections that by their nature should survive termination (including intellectual property, disclaimers, and limitation of liability) shall survive.")

            sectionHeader("14. Governing Law and Dispute Resolution")
            bodyText("These Terms are governed by and construed in accordance with the laws of the United States and the state in which The Punch is headquartered, without regard to its conflict of law provisions.")
            bodyText("Any disputes arising out of or relating to these Terms or the App shall first be attempted to be resolved through informal negotiation. If not resolved within 30 days, disputes shall be submitted to binding arbitration in accordance with the rules of the American Arbitration Association.")
            bodyText("You waive any right to participate in a class action lawsuit or class-wide arbitration.")

            sectionHeader("15. Changes to These Terms")
            bodyText("We reserve the right to modify these Terms at any time. When we make material changes, we will update the effective date at the top of this document and notify users through the App or by email. Your continued use of the App after any changes constitutes your acceptance of the new Terms.")

            sectionHeader("16. Contact Us")
            bodyText("If you have any questions or concerns about these Terms, please contact us at:")
            bodyText("The Punch HQ\nEmail: thepunchhq@gmail.com")
        }
    }
}

// MARK: - Privacy Content

private struct PrivacyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            bodyText("Effective Date: March 23, 2026")
                .italic()
            bodyText("This Privacy Policy explains how The Punch (\"we,\" \"us,\" or \"our\") collects, uses, stores, and shares information about you when you use The Punch mobile application (\"App\"). By using the App, you acknowledge that you have read and understood this Privacy Policy.")

            sectionHeader("1. Information We Collect")
            subHeader("1.1 Information You Provide")
            bodyText("When you create an account or use the App, we collect:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("Name and email address provided at registration.")
                bulletText("Password (stored in hashed/encrypted form; we never store plain-text passwords).")
                bulletText("Profile photos you upload.")
                bulletText("Posts, comments, and other content you create or share within the App.")
            }

            subHeader("1.2 Information Collected Automatically")
            bodyText("When you use the App, we and our service providers may automatically collect:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("Device information such as device type, operating system version, and unique device identifiers.")
                bulletText("Usage data such as features accessed, actions taken, and session duration, collected through Firebase Analytics.")
                bulletText("Log data including IP address, timestamps, and crash reports.")
            }

            subHeader("1.3 Information We Do Not Collect")
            bodyText("We do not collect payment information, precise GPS location, or any biometric data. We do not serve advertisements and do not collect data for advertising purposes.")

            sectionHeader("2. How We Use Your Information")
            bodyText("We use the information we collect to:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("Create and manage your account.")
                bulletText("Display your profile and content to other users of the App.")
                bulletText("Operate, maintain, and improve the App.")
                bulletText("Respond to your support requests and communications.")
                bulletText("Detect and prevent fraud, abuse, and violations of our Terms and Conditions.")
                bulletText("Analyze usage trends through Firebase Analytics to understand how the App is used.")
                bulletText("Send you important notices about the App, such as updates to these policies.")
                bulletText("Send you push notifications related to your activity on the App, including reminders, updates, and interactions. You can control notification preferences through your device settings.")
            }

            sectionHeader("3. How We Share Your Information")
            subHeader("3.1 With Other Users")
            bodyText("Your profile information (name, profile photo) and the content you post (posts and comments) are visible to other users of the App as part of the core functionality of the service. Content you post on The Punch may be publicly visible to other users of the App and may be accessible to anyone with access to the platform.")

            subHeader("3.2 With Service Providers")
            bodyText("We share information with third-party service providers who help us operate the App, including:")
            bulletText("Firebase (Google LLC) — for authentication, database storage, and analytics. Firebase's privacy practices are governed by Google's Privacy Policy at https://policies.google.com/privacy.")
            bodyText("Your information may be transferred to and processed in countries other than your own, including the United States, where our service providers operate. These providers are contractually obligated to use your information only as necessary to provide services to us and in compliance with applicable law.")

            subHeader("3.3 Legal Requirements")
            bodyText("We may disclose your information if required to do so by law or in response to valid legal process (such as a court order or subpoena), or if we believe disclosure is necessary to protect the rights, property, or safety of The Punch, our users, or the public.")

            subHeader("3.4 We Do Not Sell Your Data")
            bodyText("We do not sell, rent, or trade your personal information to third parties for their marketing or commercial purposes.")

            sectionHeader("4. Data Retention")
            bodyText("We retain your personal information for as long as your account is active or as needed to provide you with the App. When you delete your account, we will delete your personal data, including your name, email, profile photo, and all posts and comments you have made, within 30 days, except where retention is required by law or for legitimate business purposes such as fraud prevention and dispute resolution.")
            bodyText("We may retain certain anonymized or aggregated data that cannot reasonably be used to identify you for analytical purposes after your account is deleted.")

            sectionHeader("5. Your Rights and Choices")
            subHeader("5.1 Account Deletion")
            bodyText("You may delete your account at any time through the App settings. Upon deletion, your personal information and content will be permanently removed from our systems within 30 days, subject to any legal retention obligations.")

            subHeader("5.2 Updating Your Information")
            bodyText("You may update your name and profile photo at any time through your account settings within the App.")

            subHeader("5.3 Account Security Responsibility")
            bodyText("You are responsible for maintaining the confidentiality of your account credentials.")

            subHeader("5.4 California Residents (CCPA)")
            bodyText("If you are a California resident, you have the right to:")
            VStack(alignment: .leading, spacing: 6) {
                bulletText("Know what personal information we collect and how it is used.")
                bulletText("Request deletion of your personal information.")
                bulletText("Opt out of the sale of your personal information (note: we do not sell personal information).")
                bulletText("Non-discrimination for exercising your privacy rights.")
            }
            bodyText("To exercise these rights, contact us at the email address listed in Section 10.")

            subHeader("5.5 Users in the European Economic Area (EEA/UK)")
            bodyText("If you are located in the EEA or UK, you have rights under the GDPR, including the right to access, correct, or delete your personal data, and the right to data portability. To make a request, contact us at the email address in Section 10. Our legal basis for processing your data is your consent (for optional data) and the performance of our contract with you (for data necessary to operate the App).")

            sectionHeader("6. Children's Privacy")
            bodyText("The Punch is not intended for individuals under the age of 18. We do not knowingly collect personal information from individuals under 18. If we become aware that a user under 18 has provided personal information, we will delete such information promptly.")
            bodyText("If you are a parent or guardian and believe your child has provided us with personal information, please contact us at the address in Section 10.")

            sectionHeader("7. Security")
            bodyText("We implement reasonable technical and organizational measures to protect your personal information against unauthorized access, loss, or misuse. These measures include encrypted password storage, HTTPS data transmission, and access controls on our backend systems.")
            bodyText("However, no method of transmission over the internet or electronic storage is 100% secure. We cannot guarantee the absolute security of your information.")

            sectionHeader("8. DMCA and Copyright Agent")
            bodyText("The Punch respects the intellectual property rights of others. If you believe that content on the App infringes your copyright, please send a DMCA takedown notice to our designated Copyright Agent at:")
            bodyText("Copyright Agent — The Punch\nEmail: dmca@thepunch.app [UPDATE WITH ACTUAL DMCA EMAIL]\nMailing Address: [YOUR REGISTERED ADDRESS]")
            bodyText("Your DMCA notice must include: (1) a description of the copyrighted work; (2) a description of where the infringing material is located on the App; (3) your contact information; (4) a statement of good faith belief that the use is not authorized; (5) a statement of accuracy under penalty of perjury; and (6) your physical or electronic signature.")

            sectionHeader("9. Changes to This Privacy Policy")
            bodyText("We may update this Privacy Policy from time to time. When we do, we will revise the effective date at the top of this document and notify you through the App or by email. We encourage you to review this policy periodically.")

            sectionHeader("10. Contact Us")
            bodyText("If you have any questions, concerns, or requests regarding this Privacy Policy, please contact us at:")
            bodyText("The Punch HQ\nEmail: thepunchhq@gmail.com")
        }
    }
}
