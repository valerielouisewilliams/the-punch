//
//  Post.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

// Main Post Model
struct Post: Codable, Identifiable, Equatable {
    var id: Int
    var text: String
    var feelingEmoji: String?
    var feelingName: String?
    var createdAt: String
    var updatedAt: String
    
    // Always included from backend
    var author: PostAuthor
    var stats: PostStats
    
    // Optional - only in detail views
    var comments: [Comment]?
}

// Post Author
struct PostAuthor: Codable, Equatable {
    let id: Int
    let username: String
    var displayName: String?
    var avatarUrl: String?
    
    var displayNameOrUsername: String {
        displayName ?? username
    }
}

// Post Statistics
struct PostStats: Codable, Equatable {
    var likeCount: Int
    var commentCount: Int
    var userHasLiked: Bool
}


