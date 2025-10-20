//
//  APIService.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    // Backend URL
    private let baseURL = "http://localhost:3000/api"
    
    private init() {}
    
    // Helper Method for Making Requests
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        token: String? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        // Create URL
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if provided
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Debug stuff: Print response for troubleshooting
        #if DEBUG
        print("[\(method)] \(endpoint) - Status: \(httpResponse.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response: \(jsonString)")
        }
        #endif
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            print("Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(jsonString)")
            }
            throw APIError.decodingError
        }
    }
    

    
    // Authentication Endpoints
    
    /// Register a new user
    func register(username: String, email: String, password: String, displayName: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "username": username,
            "email": email,
            "password": password,
            "display_name": displayName
        ]
        
        return try await makeRequest(
            endpoint: "/auth/register",
            method: "POST",
            body: body,
            responseType: AuthResponse.self,
        )
    }
    
    /// Login with email and password
    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        return try await makeRequest(
            endpoint: "/auth/login",
            method: "POST",
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    /// Get current authenticated user
    func getCurrentUser(token: String) async throws -> UserResponse {
        return try await makeRequest(
            endpoint: "/auth/me",
            method: "GET",
            token: token,
            responseType: UserResponse.self
        )
    }
    
    // Post Endpoints
    
    /// Feed (followed users + self) //TODO: need to majorly fix this
    func getFeed(limit: Int = 50, offset: Int = 0, token: String) async throws -> PostsResponse {
        // Append query params to the endpoint for GET
        let endpoint = "/posts/feed?limit=\(limit)&offset=\(offset)"
        return try await makeRequest(
            endpoint: endpoint,
            method: "GET",
            token: token,
            responseType: PostsResponse.self
        )
    }
    
    /// Get all posts (with optional authentication)
    func getPosts(token: String? = nil) async throws -> PostsResponse {
        return try await makeRequest(
            endpoint: "/posts",
            method: "GET",
            token: token,
            responseType: PostsResponse.self
        )
    }
    
    /// Get a single post by ID with comments and like count
    func getPost(id: Int, token: String? = nil) async throws -> PostDetailResponse {
        return try await makeRequest(
            endpoint: "/posts/\(id)",
            method: "GET",
            token: token,
            responseType: PostDetailResponse.self
        )
    }
    
    /// Create a new post (requires authentication)
    func createPost(text: String, emoji: String, token: String) async throws -> PostResponse {
        let body: [String: Any] = [
            "text": text,
            "feeling_emoji": emoji
        ]
        
        return try await makeRequest(
            endpoint: "/posts",
            method: "POST",
            body: body,
            token: token,
            responseType: PostResponse.self
        )
    }
    
    /// Update an existing post (requires authentication and ownership)
    func updatePost(id: Int, text: String, emoji: String, token: String) async throws -> PostResponse {
        let body: [String: Any] = [
            "text": text,
            "feeling_emoji": emoji
        ]
        
        return try await makeRequest(
            endpoint: "/posts/\(id)",
            method: "PUT",
            body: body,
            token: token,
            responseType: PostResponse.self
        )
    }
    
    /// Delete a post (requires authentication and ownership)
    func deletePost(id: Int, token: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/posts/\(id)",
            method: "DELETE",
            token: token,
            responseType: MessageResponse.self
        )
    }
    
    /// Get all posts by a specific user
    func getUserPosts(userId: Int, token: String? = nil) async throws -> PostsResponse {
        return try await makeRequest(
            endpoint: "/posts/user/\(userId)",
            method: "GET",
            token: token,
            responseType: PostsResponse.self
        )
    }
    
    // Like Endpoints
    
    /// Like a post (requires authentication)
    func likePost(postId: Int, token: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/likes/post/\(postId)",
            method: "POST",
            token: token,
            responseType: MessageResponse.self
        )
    }
    
    /// Unlike a post (requires authentication)
    func unlikePost(postId: Int, token: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/likes/post/\(postId)",
            method: "DELETE",
            token: token,
            responseType: MessageResponse.self
        )
    }
    
    /// Get all likes for a post
    func getLikes(postId: Int, token: String? = nil) async throws -> LikesResponse {
        return try await makeRequest(
            endpoint: "/likes/post/\(postId)",
            method: "GET",
            token: token,
            responseType: LikesResponse.self
        )
    }
    
    /// Check if current user has liked a post (requires authentication)
    func checkIfLiked(postId: Int, token: String) async throws -> LikeStatusResponse {
        return try await makeRequest(
            endpoint: "/likes/post/\(postId)/check",
            method: "GET",
            token: token,
            responseType: LikeStatusResponse.self
        )
    }
    
    // Comment Endpoints
    
    /// Create a comment on a post (requires authentication)
    func createComment(postId: Int, text: String, token: String) async throws -> CommentResponse {
        let body: [String: Any] = [
            "text": text
        ]
        
        return try await makeRequest(
            endpoint: "/comments/post/\(postId)",
            method: "POST",
            body: body,
            token: token,
            responseType: CommentResponse.self
        )
    }
    
    /// Get all comments for a post
    func getComments(postId: Int, token: String? = nil) async throws -> CommentsResponse {
        return try await makeRequest(
            endpoint: "/comments/post/\(postId)",
            method: "GET",
            token: token,
            responseType: CommentsResponse.self
        )
    }
    
    /// Delete a comment (requires authentication and ownership)
    func deleteComment(id: Int, token: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/comments/\(id)",
            method: "DELETE",
            token: token,
            responseType: MessageResponse.self
        )
    }
    
    // Follow Endpoints
    
    /// Follow a user (requires authentication)
    func followUser(userId: Int, token: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/follows/user/\(userId)",
            method: "POST",
            token: token,
            responseType: MessageResponse.self
        )
    }
    
    /// Unfollow a user (requires authentication)
    func unfollowUser(userId: Int, token: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/follows/user/\(userId)",
            method: "DELETE",
            token: token,
            responseType: MessageResponse.self
        )
    }
    
    /// Check if current user is following another user (requires authentication)
    func checkIfFollowing(userId: Int, token: String) async throws -> FollowStatusResponse {
        return try await makeRequest(
            endpoint: "/follows/user/\(userId)/check",
            method: "GET",
            token: token,
            responseType: FollowStatusResponse.self
        )
    }
    
    // User Endpoints
    
    /// Get user profile by ID
    func getUserProfile(userId: Int, token: String? = nil) async throws -> UserResponse {
        return try await makeRequest(
            endpoint: "/users/\(userId)",
            method: "GET",
            token: token,
            responseType: UserResponse.self
        )
    }
    
    /// Get user profile by username
    func getUserByUsername(username: String, token: String? = nil) async throws -> UserResponse {
        return try await makeRequest(
            endpoint: "/users/username/\(username)",
            method: "GET",
            token: token,
            responseType: UserResponse.self
        )
    }
    
    /// Get a user's followers
    func getFollowers(userId: Int, token: String? = nil) async throws -> FollowersResponse {
        return try await makeRequest(
            endpoint: "/users/\(userId)/followers",
            method: "GET",
            token: token,
            responseType: FollowersResponse.self
        )
    }
    
    /// Get users that a user is following
    func getFollowing(userId: Int, token: String? = nil) async throws -> FollowersResponse {
        return try await makeRequest(
            endpoint: "/users/\(userId)/following",
            method: "GET",
            token: token,
            responseType: FollowersResponse.self
        )
    }
}

// API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            switch code {
            case 400:
                return "Bad request - check your input"
            case 401:
                return "Unauthorized - please login again"
            case 403:
                return "Forbidden - you don't have permission"
            case 404:
                return "Not found"
            case 409:
                return "Conflict - resource already exists"
            case 500...599:
                return "Server error - please try again later"
            default:
                return "HTTP Error: \(code)"
            }
        case .decodingError:
            return "Failed to decode response"
        case .noToken:
            return "No authentication token found"
        }
    }
}
