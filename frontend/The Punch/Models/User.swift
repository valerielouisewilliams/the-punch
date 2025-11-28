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
    var avatarUrl: String? { get }
}

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    var displayName: String
    var bio: String?
    let createdAt: String
    var followerCount: Int?
    var followingCount: Int?
    var avatarUrl: String?
    var isFollowing: Bool?
}

struct UserProfile: Codable, Identifiable {
    let id: Int
    let username: String
    let displayName: String
    let bio: String?
    let avatarUrl: String?
}

extension User: UserDisplayable {}
extension UserProfile: UserDisplayable {}

