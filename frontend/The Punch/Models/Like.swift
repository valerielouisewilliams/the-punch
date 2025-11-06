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
    
    private enum CodingKeys: String, CodingKey { //to match backend, quick fix but should clean up
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case username
    }
    
}
