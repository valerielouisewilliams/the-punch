//
//  User.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let displayName: String
    let bio: String?
    let createdAt: String
    let followerCount: Int?
    let followingCount: Int?
    let avatarUrl: String?
}

struct UserProfile: Codable, Identifiable {
    let id: Int
    let username: String
    let displayName: String
    let bio: String?
}
