//
//  ProfileHeaderView.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/20/25.
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture with Orange Border
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.95, green: 0.60, blue: 0.20), lineWidth: 3)
                )
                .overlay(
                    Text(user.username.prefix(1).uppercased())
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                )

            // Username and Display Name
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text("@\(user.username)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }

            // Bio
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Stats Row (Themed)
            HStack(spacing: 30) {
                StatView(
                    count: 0,
                    label: "POSTS"
                )

                StatView(
                    count: user.followerCount ?? 0,
                    label: "FOLLOWERS"
                )

                StatView(
                    count: user.followingCount ?? 0,
                    label: "FOLLOWING"
                )
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.07))
        )
        .padding(.horizontal)
    }
}
