//
//  OrangeButton.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

struct OrangeButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.95, green: 0.60, blue: 0.20))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}
