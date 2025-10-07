//
//  User.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

/**
 User structure
 */
struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let username: String
    let displayName: String?
    let bio: String?
    let punches: Int
    let friends: Int
    let streak: Int
    let feeling: String?
    let emoji: String?
    let isFriend: Bool
}
