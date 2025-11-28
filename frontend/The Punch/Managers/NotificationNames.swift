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

extension NSNotification.Name {
    static let postDidDelete = NSNotification.Name("postDidDelete")
}

// Comments
extension Notification.Name {
    static let commentDidCreate = Notification.Name("commentDidCreate")
    static let commentDidDelete = Notification.Name("commentDidDelete")
}

// Follows
extension Notification.Name {
    static let followDidChange = Notification.Name("followDidChange")
}

// Profile updates
extension NSNotification.Name {
    static let userProfileDidUpdate = NSNotification.Name("userProfileDidUpdate")
}


