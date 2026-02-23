//
//  NotificationsView.swift
//  ThePunch
//
//  Created by Valerie Williams on 2/22/26.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var vm: NotificationsViewModel

    var body: some View {
        List {
            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }

            ForEach(vm.items) { n in
                HStack(alignment: .top, spacing: 12) {

                    // unread dot (hidden for read)
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(n.isUnread ? .blue : .clear)
                        .padding(.top, 12)

                    AvatarView(
                        urlString: n.actorAvatarUrl,
                        fallbackText: n.actorNameForDisplay,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.displayText(for: n))
                            .font(.subheadline)
                            .fontWeight(n.isUnread ? .semibold : .regular)
                            .foregroundStyle(n.isUnread ? .primary : .secondary)

                        Text(TimestampFormatter.shared.format(n.createdAt, style: .smart))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // optional: tapping marks read too
                    Task { await vm.markRead(n.id) }
                }

                // Swipe LEFT (trailing): Clear / delete
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await vm.delete(n.id) }
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }

                // Swipe RIGHT (leading): Mark as read (only show if unread)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if n.isUnread {
                        Button {
                            Task { await vm.markRead(n.id) }
                        } label: {
                            Label("Read", systemImage: "checkmark.circle")
                        }
                        .tint(.blue)
                    }
                }
            }}
        .overlay { if vm.isLoading { ProgressView() } }
        .navigationTitle("Notifications")
        .task { await vm.loadInbox(unreadOnly: false) }
    }
}
