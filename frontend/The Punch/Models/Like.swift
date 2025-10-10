//
//  Like.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/10/25.
//

import Foundation

struct Like: Codable, Identifiable {
    let id: Int
    let postId: Int
    let userId: Int
    let createdAt: String
    let username: String?
}
