//
//  AvatarView.swift
//  ThePunch
//
//  Created by Valerie Williams on 2/23/26.
//


import SwiftUI

struct AvatarView: View {
    let urlString: String?
    let fallbackText: String
    var size: CGFloat = 38

    var body: some View {
        Group {
            if let urlString,
               let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().scaleEffect(0.7)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallback: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.2))
            Text(initials(from: fallbackText))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }

        if parts.isEmpty { return "?" }
        if parts.count == 1 {
            return String(parts[0].prefix(2)).uppercased()
        }
        return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
    }
}
