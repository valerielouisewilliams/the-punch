//
//  UserProfileHeader.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

struct UserProfileHeader: View {
    let user: User
    let isOwnProfile: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            // Username
            Text(user.username)
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            // Stats
            HStack(spacing: 32) {
                VStack {
                    Text("\(user.punches)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("punches")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
                VStack {
                    Text("\(user.friends)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("friends")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
                VStack {
                    Text("\(user.streak)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("streak")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            // Avatar + bio
            HStack(alignment: .center, spacing: 16) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(user.bio ?? "Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint.")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(3)
                    
                    HStack(spacing: 6) {
                        Text("FEELING:")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(user.feeling ?? "Catty")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white)
                        Text(user.emoji ?? "😍")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            
            // Edit Profile Button
            if isOwnProfile {
                Button(action: {
                    print("Edit profile tapped") //TODO: navigate to an edit profile page
                }) {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("Edit Profile")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.pink)
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
            
            Divider().overlay(Color.white.opacity(0.2))
        }
        .padding(.vertical)
    }
}
