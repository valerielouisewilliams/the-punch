//
//  Comment.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/10/25.
//

import Foundation

// Comment
struct Comment: Codable, Identifiable, Equatable {
    let id: Int
    let postId: Int
    let userId: Int
    let text: String
    let createdAt: String
    let user: PostAuthor?  // Reuses PostAuthor structure
}
