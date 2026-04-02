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
    var phoneNumber: String?
    var discoverableByPhone: Bool?

    enum CodingKeys: String, CodingKey {
        case id, username, email, bio
        case displayName
        case createdAt
        case followerCount
        case followingCount
        case avatarUrl
        case isFollowing
        case phoneNumber
        case discoverableByPhone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        displayName = try c.decode(String.self, forKey: .displayName)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        followerCount = try c.decodeIfPresent(Int.self, forKey: .followerCount)
        followingCount = try c.decodeIfPresent(Int.self, forKey: .followingCount)
        avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
        isFollowing = try c.decodeIfPresent(Bool.self, forKey: .isFollowing)
        phoneNumber = try c.decodeIfPresent(String.self, forKey: .phoneNumber)

        if let boolValue = try c.decodeIfPresent(Bool.self, forKey: .discoverableByPhone) {
            discoverableByPhone = boolValue
        } else if let intValue = try c.decodeIfPresent(Int.self, forKey: .discoverableByPhone) {
            discoverableByPhone = (intValue != 0)
        } else {
            discoverableByPhone = nil
        }
    }
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

struct UpdateAccountInformationRequest: Encodable {
    let phoneNumber: String?

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
    }
}
