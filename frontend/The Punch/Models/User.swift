//
//  User.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

// Used by lists (followers, following, search) & by UserRow
protocol UserDisplayable: Identifiable {
    var id: Int { get }
    var username: String { get }
    var displayName: String { get }
    var bio: String? { get }
}

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
    let isFollowing: Bool?
}

struct UserProfile: Codable, Identifiable {
    let id: Int
    let username: String
    let displayName: String
    let bio: String?
}

extension User: UserDisplayable {}
extension UserProfile: UserDisplayable {}

