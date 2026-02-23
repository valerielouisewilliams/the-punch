//
//  BellButton.swift
//  ThePunch
//
//  Created by Valerie Williams on 2/22/26.
//


import SwiftUI

struct BellButton: View {
    let unread: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: unread > 0 ? "bell.fill" : "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(unread > 0 ? .primary : .primary)
            }
        }
        .accessibilityLabel("Notifications")
    }
}
