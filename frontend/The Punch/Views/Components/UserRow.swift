//  UserRow.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

struct UserRow: View {
    let user: any UserDisplayable
    
    var body: some View {
        HStack(spacing: 12) {
            avatarView   // 👈 new

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("@\(user.username)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Avatar

    private var avatarView: some View {
        Group {
            if let urlString = avatarURLString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(displayName.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
    }

    private var avatarURLString: String? {
        if let fullUser = user as? User {
            return fullUser.avatarUrl
        }
        if let profile = user as? UserProfile {
            return profile.avatarUrl
        }
        return nil
    }


    private var displayName: String {
        // keep your existing logic; adjust to your protocol if needed
        if let fullUser = user as? User {
            return fullUser.displayName.isEmpty ? fullUser.username : fullUser.displayName
        }
        if let profile = user as? UserProfile {
            return profile.displayName.isEmpty ? profile.username : profile.displayName
        }
        return user.username
    }
}
