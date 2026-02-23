//
//  NotificationsViewModel.swift
//  ThePunch
//
//  Created by Valerie Williams on 2/22/26.
//

import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var items: [NotificationItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    func refreshUnreadCount() async {
        do {
            let resp = try await APIService.shared.getUnreadCount()
            unreadCount = resp.unread
        } catch {
            print("Unread count failed:", error)
        }
    }

    func loadInbox(unreadOnly: Bool = true) async {
        isLoading = true
        errorMessage = nil
        do {
            let resp = try await APIService.shared.getInbox(limit: 50, unreadOnly: unreadOnly)
            items = resp.data
            unreadCount = resp.data.filter { $0.isUnread }.count
        } catch {
            errorMessage = "Failed to load notifications"
            print("Inbox load failed:", error)
        }
        isLoading = false
    }

    func markRead(_ id: Int) async {
        // optimistic badge update
        if let idx = items.firstIndex(where: { $0.id == id }), items[idx].isUnread {
            unreadCount = max(0, unreadCount - 1)
        }
        do {
            _ = try await APIService.shared.markNotificationRead(id: id)
        } catch {
            print("Mark read failed:", error)
            await refreshUnreadCount()
        }
    }

    func delete(_ id: Int) async {
        // optimistic remove
        if let idx = items.firstIndex(where: { $0.id == id }) {
            if items[idx].isUnread { unreadCount = max(0, unreadCount - 1) }
            items.remove(at: idx)
        }
        do {
            _ = try await APIService.shared.deleteNotification(id: id)
        } catch {
            print("Delete failed:", error)
            await loadInbox(unreadOnly: false)
            await refreshUnreadCount()
        }
    }

    func markAllRead() async {
        do {
            _ = try await APIService.shared.markAllNotificationsRead()
            await loadInbox(unreadOnly: false)
            await refreshUnreadCount()
        } catch {
            errorMessage = "Failed to mark all as read"
            print("Mark all read failed:", error)
        }
    }

    func displayText(for n: NotificationItem) -> String {
        let name = n.actorNameForDisplay
        switch n.type.lowercased() {
        case "follow":
            return "\(name) followed you"
        case "like":
            return "\(name) liked your post"
        case "comment":
            return "\(name) commented on your post"
        default:
            return n.message ?? "Notification"
        }
    }
}
