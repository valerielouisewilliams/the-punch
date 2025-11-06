//
//  Post.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

// Main Post Model
struct Post: Codable, Identifiable, Equatable {
    let id: Int
    let text: String
    let feelingEmoji: String?
    let feelingName: String?
    let createdAt: String
    let updatedAt: String
    
    // Always included from backend
    let author: PostAuthor
    let stats: PostStats
    
    // Optional - only in detail views
    let comments: [Comment]?
}

// Post Author
struct PostAuthor: Codable, Equatable {
    let id: Int
    let username: String
    let displayName: String?
    let avatarUrl: String?
    
    var displayNameOrUsername: String {
        displayName ?? username
    }
}

// Post Statistics
struct PostStats: Codable, Equatable {
    let likeCount: Int
    let commentCount: Int
    let userHasLiked: Bool
}


