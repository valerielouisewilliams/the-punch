//
//  APIResponses.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/10/25.
//

import Foundation

// Auth Responses

struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let data: AuthData
}

struct AuthData: Codable {
    let user: User
    let token: String
}

// User Responses

struct UserResponse: Codable {
    let success: Bool
    let data: User
}

struct FollowersResponse: Codable {
    let success: Bool
    let count: Int
    let data: [UserProfile]
}

// Post Responses

struct PostsResponse: Codable {
    let success: Bool
    let data: [Post]
    let count: Int
}

struct SinglePostResponse: Codable {
    let success: Bool
    let data: Post
}

struct FeedResponse: Codable {
    let success: Bool
    let data: FeedData?
    let message: String?
}

struct FeedData: Codable {
    let posts: [Post]  // Same Post model!
    let pagination: FeedPagination
    let filters: FeedFilters?
}

struct FeedPagination: Codable {
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

struct FeedFilters: Codable {
    let timeWindow: String?
    let includesOwnPosts: Bool?
}


// Comment Responses

struct CommentResponse: Codable {
    let success: Bool
    let message: String
    let comment: Comment
}

struct CommentsResponse: Codable {
    let success: Bool
    let count: Int
    let data: [Comment]
}

// Like Responses

struct LikesResponse: Codable {
    let success: Bool
    let count: Int
    let likes: [Like]
}

struct LikeStatusResponse: Codable {
    let success: Bool
    let liked: Bool
}

// Follow Responses

struct FollowStatusResponse: Codable {
    let success: Bool
    let following: Bool
}

// Generic Responses

struct MessageResponse: Codable {
    let message: String
    let like: Like?
}
