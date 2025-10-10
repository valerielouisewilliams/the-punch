//
//  APIService.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

class APIService {
    // singleton: shared instance to use anywhere in the app
    static let shared = APIService()
    
    // base URL of backend API
    private let baseURL = URL(string: "http://localhost:3000/api")!
    
    // initializer
    private init() {}
    
    // helper method for making api requests
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        token: String? = nil,
        responseType: T.Type
    ) async throws -> T {
        // create URL
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            fatalError("Invalid URL")
        }
        
        // create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // add auth token if needed
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // add body if needed
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        // make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // check status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
                
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
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
            return "HTTP Error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .noToken:
            return "No authentication token"
        }
    }
}
