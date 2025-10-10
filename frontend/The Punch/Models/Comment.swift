//
//  Comment.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/10/25.
//

import Foundation

struct Comment: Codable, Identifiable {
    let id: Int
    let postId: Int
    let userId: Int
    let text: String
    let createdAt: String
    let username: String
    let displayName: String?
}
