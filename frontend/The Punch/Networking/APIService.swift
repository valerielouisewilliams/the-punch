//
//  APIService.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

class APIService {
    // Singleton: shared instance to use anywhere in your app
    static let shared = APIService()
    
    // Base URL of backend API
    private let baseURL = URL(string: "http://localhost:3000/api")!
}

