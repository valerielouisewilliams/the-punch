//
//  PunchButton.swift
//  ThePunch
//
//  Created by Valerie Williams on 3/23/26.
//

import SwiftUI

struct PunchButton: View {
    let targetUserId: Int
    let isCurrentUser: Bool

    @StateObject private var viewModel = PunchButtonViewModel()

    var body: some View {
        if !isCurrentUser {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()

                Task {
                    await viewModel.sendPunch(to: targetUserId)
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.didSend ? "💥 Punched!" : "🥊 Punch")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)
        }
    }
}
