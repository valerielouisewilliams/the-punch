//
//  Post.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import Foundation

/**
 Post structure
 */
struct Post: Identifiable, Codable {
    let id: UUID
    let username: String
    let timestamp: Date
    let content: String
    let feeling: String
    let emoji: String
}

/**
 Fake data for testing purposes
 */
extension Post {
    static func samplePosts() -> [Post] {
        [
            Post(
                id: UUID(),
                username: "valerie",
                timestamp: Date().addingTimeInterval(-30),
                content: "Feeling hecka productive today!",
                feeling: "Energetic",
                emoji: "⚡️"
            ),
            Post(
                id: UUID(),
                username: "Sydney",
                timestamp: Date().addingTimeInterval(-240),
                content: "Meow ☕️🎶",
                feeling: "Chill",
                emoji: "😌"
            ),
            Post(
                id: UUID(),
                username: "Cat",
                timestamp: Date().addingTimeInterval(-600),
                content: "HejshJDHJHJGH",
                feeling: "Tired",
                emoji: "😴"
            ),
            Post(
                id: UUID(),
                username: "MAYA",
                timestamp: Date().addingTimeInterval(-1200),
                content: "My bday is soon!",
                feeling: "Curious",
                emoji: "🤓"
            )
        ]
    }
}
