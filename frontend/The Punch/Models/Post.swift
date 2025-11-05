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

struct FeedPost: Codable, Identifiable, Equatable {
    let id: Int
    let text: String
    let feelingEmoji: String?
    let createdAt: String
    let updatedAt: String
    let user: PostUser
    let engagement: PostEngagement
}

struct PostUser: Codable, Equatable {
    let id: Int
    let username: String
    let displayName: String?
    let avatarUrl: String?
    
    var displayNameOrUsername: String {
        return displayName ?? username
    }
}

struct PostEngagement: Codable, Equatable {
    let likeCount: Int
    let commentCount: Int
    let userHasLiked: Bool
}
