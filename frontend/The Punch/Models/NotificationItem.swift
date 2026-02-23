//
//  NotificationItem.swift
//  ThePunch
//
//  Created by Valerie Williams on 2/22/26.
//


struct NotificationItem: Decodable, Identifiable, Equatable {
    let id: Int
    let recipientUserId: Int
    let actorUserId: Int?
    let type: String
    let entityType: String?
    let entityId: Int?
    let message: String?
    let createdAt: String
    let readAt: String?
    let isDeleted: Int
    let actorUsername: String?
    let actorDisplayName: String?
    let actorAvatarUrl: String?

    var isUnread: Bool { readAt == nil }

    var actorNameForDisplay: String {
        actorDisplayName?.isEmpty == false ? actorDisplayName! :
        actorUsername?.isEmpty == false ? actorUsername! :
        "Someone"
    }
}
