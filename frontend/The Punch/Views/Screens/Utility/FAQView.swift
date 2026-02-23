//
//  FAQView.swift
//  ThePunch
//
//  Created by Sydney Patel on 2/22/26.
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [FAQItem]
}

struct FAQView: View {
    @State private var expandedId: UUID? = nil

    private let sections: [FAQSection] = [
        FAQSection(title: "Getting Started", items: [
            FAQItem(question: "What is The Punch?",
                    answer: "The Punch is a social app where you can share short posts called Punches — quick thoughts, feelings, and moments with your friends!"),
            FAQItem(question: "How do I create an account?",
                    answer: "Tap 'Don't have an account? Sign Up' on the login screen. Then, fill in your username, display name, email, and password. Finally, accept the terms, and you're in."),
            FAQItem(question: "How do I reset my password?",
                    answer: "Coming soon!"),
        ]),
        FAQSection(title: "Posting", items: [
            FAQItem(question: "What is a Punch?",
                    answer: "A Punch is a post on The Punch — quick thoughts, feelings, moments from your day. You can add a Feeling tag and an emoji to give your Punch some extra personality."),
            FAQItem(question: "How long can a Punch be?",
                    answer: "Punches can be up to 280 characters. A counter in the post composer shows how many characters you have left."),
            FAQItem(question: "Can I edit a Punch after posting?",
                    answer: "Not currently. If you made a mistake, you can delete the Punch from your profile and repost it."),
            FAQItem(question: "How do I delete a Punch?",
                    answer: "Go to your profile, find the Punch, and tap the trash icon in the top right of the post card."),
            FAQItem(question: "Can I add links to a Punch?",
                    answer: "Yes! Just paste or type a URL in your Punch and it will automatically be underlined/colored and made tappable on the feed once posted."),
        ]),
        FAQSection(title: "Feelings & Emojis", items: [
            FAQItem(question: "What is the Feeling feature?",
                    answer: "When creating a Punch, you can express how you're feeling — like 'Happy', 'Chill', or anything you type. It shows up as a badge on your Punch."),
            FAQItem(question: "How do I add an emoji to my Punch?",
                    answer: "In the Punch composer, scroll down to the Emoji section and tap 'Open Picker' to choose one emoji to attach to your Punch."),
        ]),
        FAQSection(title: "Social", items: [
            FAQItem(question: "How do I follow someone?",
                    answer: "Tap on any user's profile picture or display name to visit their profile, then tap the Follow button."),
            FAQItem(question: "How do I find friends on ThePunch?",
                    answer: "Use the Search tab to find people by username or display name."),
            FAQItem(question: "Can I make my profile private?",
                    answer: "Private profiles are not currently supported, but this feature is on our roadmap."),
            FAQItem(question: "How do I report a user?",
                    answer: "We're actively working on an in-app reporting feature.")
        ]),
        FAQSection(title: "Feed & Interacting", items: [
            FAQItem(question: "Why don't I see all posts in my feed?",
                    answer: "Your feed shows Punches from people you follow. Go to the search icon to find new friends to follow!"),
            FAQItem(question: "How do I refresh my feed?",
                    answer: "Pull down on the feed to refresh, or tap the refresh button in the top right corner."),
            FAQItem(question: "Can I like and comment on someone's Punch",
                    answer: "Yes! You can press the like or comment buttons at the bottom of any post to interact with it. Then, you can click on their post to view the comments."),
        ]),
        FAQSection(title: "Account & Settings", items: [
            FAQItem(question: "How do I change my display name or bio?",
                    answer: "Go to Settings → Edit Profile to update your display name, and bio."),
            FAQItem(question: "How do I change my profile picture?",
                    answer: "Go to Settings → Edit Profile and tap on your avatar to upload a new photo."),
            FAQItem(question: "How do I delete my account?",
                    answer: "Account deletion is currently handled by contacting us directly. We're working on adding a self-serve option in the app soon."),
        ]),
        FAQSection(title: "Notifications", items: [
            FAQItem(question: "Why am I not getting notifications?",
                    answer: "Make sure notifications are enabled for The Punch in your iPhone Settings → Notifications → The Punch. Also check that you've allowed notifications when prompted in the app."),
            FAQItem(question: "How do I turn off notifications?",
                    answer: "Go to your iPhone Settings → Notifications → The Punch and toggle off the notifications you don't want."),
        ]),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Frequently Asked Questions")
                            .font(.system(size: 27, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // sections
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title.uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                                .padding(.horizontal)

                            VStack(spacing: 1) {
                                ForEach(section.items) { item in
                                    FAQRow(item: item, isExpanded: expandedId == item.id) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            expandedId = expandedId == item.id ? nil : item.id
                                        }
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
        }
    }
}

struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Text(item.question)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if isExpanded {
                    Text(item.answer)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
            }
            .background(Color(red: 0.18, green: 0.16, blue: 0.16))
        }
        .buttonStyle(.plain)
    }
}
