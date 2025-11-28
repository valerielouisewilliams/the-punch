//
//  APIService.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    // Backend URL for sim testing
    //private let baseURL = "http://localhost:3000/api" // for simulator
    
    // Bckend URL for device testing
//    private let baseURL = URL(string: "http://10.74.201.159:3000/api")! // campus wifi
//    private let baseURL = URL(string: "http://10.0.0.187:3000/api")! // apartment wifi
//   private let baseURL = URL(string:"http://192.168.1.222:3000/api")! // home wifi
    private let baseURL = URL(string: "http://192.168.7.5:3000/api")! // aunties house wifi
//    private let baseURL = URL(string:"http://172.20.10.2:3000/api")! // hotel wifi
    

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
    func getPost(id: Int, token: String? = nil) async throws -> SinglePostResponse {
        return try await makeRequest(
            endpoint: "/posts/\(id)",
            method: "GET",
            token: token,
            responseType: SinglePostResponse.self
        )
    }
    
    /// Create a new post (requires authentication)
//    func createPost(text: String, emoji: String, token: String) async throws -> PostsResponse {
//        let body: [String: Any] = [
//            "text": text,
//            "feeling_emoji": emoji
//        ]
//        
//        return try await makeRequest(
//            endpoint: "/posts",
//            method: "POST",
//            body: body,
//            token: token,
//            responseType: PostsResponse.self
//        )
//    }
    
    /// Update an existing post (requires authentication and ownership)
    func updatePost(id: Int, text: String, emoji: String, token: String) async throws -> PostsResponse {
        let body: [String: Any] = [
            "text": text,
            "feeling_emoji": emoji
        ]
        
        return try await makeRequest(
            endpoint: "/posts/\(id)",
            method: "PUT",
            body: body,
            token: token,
            responseType: PostsResponse.self
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
    
//    /// Follow a user (requires authentication)
//    func followUser(userId: Int, token: String) async throws -> MessageResponse {
//        return try await makeRequest(
//            endpoint: "/follows/user/\(userId)",
//            method: "POST",
//            token: token,
//            responseType: MessageResponse.self
//        )
//    }
//    
//    /// Unfollow a user (requires authentication)
//    func unfollowUser(userId: Int, token: String) async throws -> MessageResponse {
//        return try await makeRequest(
//            endpoint: "/follows/user/\(userId)",
//            method: "DELETE",
//            token: token,
//            responseType: MessageResponse.self
//        )
//    }
//    
//    /// Check if current user is following another user (requires authentication)
//    func checkIfFollowing(userId: Int, token: String) async throws -> FollowStatusResponse {
//        return try await makeRequest(
//            endpoint: "/follows/user/\(userId)/check",
//            method: "GET",
//            token: token,
//            responseType: FollowStatusResponse.self
//        )
//    }
    
    
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
    
    // Lets a user edit their profile
    func updateUserProfile(
        displayName: String,
        bio: String?,
        avatarUrl: String?,
        token: String
    ) async throws -> UserResponse {
        
        var body: [String: Any] = [
            "display_name": displayName
        ]
        
        if let bio = bio { body["bio"] = bio }
        if let avatarUrl = avatarUrl { body["avatar_url"] = avatarUrl }
        
        return try await makeRequest(
            endpoint: "/users/me",
            method: "PUT",
            body: body,
            token: token,
            responseType: UserResponse.self
        )
    }
    
    func searchUsers(query: String, token: String? = nil) async throws -> UsersResponse {
        let escaped = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await makeRequest(
            endpoint: "/users/search?query=\(escaped)",
            method: "GET",
            token: token,
            responseType: UsersResponse.self
        )
    }


    
    // Followers Endpoints

    /// Get a user's followers (LIST VIEW)
    func getFollowersList(userId: Int, token: String? = nil) async throws -> FollowersListResponse {
        return try await makeRequest(
            endpoint: "/follows/user/\(userId)/followers",
            method: "GET",
            token: token,
            responseType: FollowersListResponse.self
        )
    }
    
    func getFollowingList(userId: Int, token: String? = nil) async throws -> FollowingListResponse {
        return try await makeRequest(
            endpoint: "/follows/user/\(userId)/following",
            method: "GET",
            token: token,
            responseType: FollowingListResponse.self
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

extension APIService {
    
    func getUserFeed(
        limit: Int = 20,
        offset: Int = 0,
        days: Int = 2,
        includeOwn: Bool = false,
        token: String
    ) async throws -> FeedResponse {
        // If backend expects 0/1 instead of true/false, send it that way:
        let includeOwnValue = includeOwn ? "1" : "0"  // or "\(includeOwn)" if server accepts true/false

        var comps = URLComponents(string: "\(baseURL)/feed")!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "days", value: String(days)),
            URLQueryItem(name: "includeOwn", value: includeOwnValue)
        ]
        guard let url = comps.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        // If your server uses x-user-id for userHasLiked, add it:
        if let uid = await AuthManager.shared.getToken() {
            req.setValue(String(uid), forHTTPHeaderField: "x-user-id")
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }

        // Loud logging helps a ton during setup
        print("GET /feed status:", http.statusCode)
        print("RAW /feed:", String(data: data, encoding: .utf8) ?? "<non-utf8>")

        // Handle non-2xx properly and surface server message if present
        guard (200...299).contains(http.statusCode) else {
            if let m = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                throw NSError(domain: "API", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(m.message)"])
            }
            let body = String(data: data, encoding: .utf8) ?? "<empty>"
            throw NSError(domain: "API", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"])
        }

        // Decode using snake_case -> camelCase to match your Swift models
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return try dec.decode(FeedResponse.self, from: data)
    }


    func getUserPosts(userId: Int, token: String) async throws -> PostsResponse {
        var req = URLRequest(url: URL(string: "\(baseURL)/posts?userId=\(userId)")!)
        req.httpMethod = "GET"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue(String(userId), forHTTPHeaderField: "x-user-id")

        let (data, resp) = try await URLSession.shared.data(for: req)

        //  Raw body before decoding
        if let http = resp as? HTTPURLResponse {
            print("GET /posts status:", http.statusCode)
        }
        print("RAW /posts JSON:\n", String(data: data, encoding: .utf8) ?? "<non-utf8>")

        // Decode
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // if your timestamps aren’t ISO8601 strings you can leave dates as String in models
        return try decoder.decode(PostsResponse.self, from: data)
    }

    
    // Get trending posts
    func getTrendingPosts(
        limit: Int = 20,
        hours: Int = 24,
        token: String?
    ) async throws -> FeedResponse {
        var components = URLComponents(string: "\(baseURL)/feed/trending")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "hours", value: String(hours))
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Optional auth for "liked" status
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                throw APIError.httpError(500)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(FeedResponse.self, from: data)
    }
}

extension APIService {
    func createPost(
        text: String,
        feelingEmoji: String?,
        feelingName: String?,
        token: String
    ) async throws -> CreatePostResponse {

        var body: [String: Any] = ["text": text]
        if let feelingEmoji { body["feeling_emoji"] = feelingEmoji }   // snake_case
        if let feelingName  { body["feeling_name"]  = feelingName  }   // snake_case

        return try await makeRequest(
            endpoint: "/posts",
            method: "POST",
            body: body,
            token: token,
            responseType: CreatePostResponse.self
        )
    }
}

extension APIService {
    func checkIfFollowing(
        userId: Int,
        token: String
    ) async throws -> FollowStatusResponse {
        return try await makeRequest(
            endpoint: "/follows/user/\(userId)/check",
            method: "GET",
            token: token,
            responseType: FollowStatusResponse.self
        )
    }

    func followUser(
        userId: Int,
        token: String
    ) async throws -> SimpleResponse {
        try await makeRequest(
            endpoint: "/follows/user/\(userId)",
            method: "POST",
            token: token,
            responseType: SimpleResponse.self
        )
    }

    func unfollowUser(
        userId: Int,
        token: String
    ) async throws -> SimpleResponse {
        try await makeRequest(
            endpoint: "/follows/user/\(userId)",
            method: "DELETE",
            token: token,
            responseType: SimpleResponse.self
        )
    }
}
