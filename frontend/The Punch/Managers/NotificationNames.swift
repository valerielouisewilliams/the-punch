//
//  NotificationNames.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/27/25.
//

import Foundation

// Posts
extension Notification.Name {
    static let postDidUpdate = Notification.Name("postDidUpdate")
}

// Comments
extension Notification.Name {
    static let commentDidCreate = Notification.Name("commentDidCreate")
    static let commentDidDelete = Notification.Name("commentDidDelete")
}
