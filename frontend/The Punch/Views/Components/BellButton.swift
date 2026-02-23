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
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))

                if unread > 0 {
                    Text(unread > 99 ? "99+" : "\(unread)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .foregroundColor(.white)
                        .offset(x: 10, y: -10)
                }
            }
        }
        .accessibilityLabel("Notifications")
    }
}