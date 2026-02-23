//
//  NotificationsView.swift
//  ThePunch
//
//  Created by Valerie Williams on 2/22/26.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var vm: NotificationsViewModel
    @State private var unreadOnly = true

    var body: some View {
        List {
            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }

            ForEach(vm.items) { n in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(n.isUnread ? .blue : .clear)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.displayText(for: n))
                            .font(.subheadline)
                            .fontWeight(n.isUnread ? .semibold : .regular)
                        
                        Text(TimestampFormatter.shared.format(n.createdAt, style: .smart))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task { await vm.markRead(n.id) }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await vm.delete(n.id) }
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
        }
        .overlay { if vm.isLoading { ProgressView() } }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Toggle("Unread", isOn: $unreadOnly).labelsHidden()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Read All") { Task { await vm.markAllRead() } }
            }
        }
        .task { await vm.loadInbox(unreadOnly: unreadOnly) }
        .onChange(of: unreadOnly) { _, newVal in
            Task { await vm.loadInbox(unreadOnly: newVal) }
        }
    }
}
