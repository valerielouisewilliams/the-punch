//
//  Post.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

struct Post: Codable, Identifiable {
    let id: Int
    let userId: Int
    
    let text: String
    let feelingEmoji: String
    let createdAt: String
    let updatedAt: String
    let isDeleted: Int
}

struct PostDetail: Codable {
    let id: Int
    let userId: Int
    let text: String
    let feelingEmoji: String
    let createdAt: String
    let updatedAt: String
    let isDeleted: Int
    let comments: [Comment]
    let likeCount: Int
}

struct FeedResponse: Codable {
    let success: Bool
    let data: [Post]
    let pagination: Pagination?
    struct Pagination: Codable { let limit: Int; let offset: Int; let count: Int }
}
