//
//  StatView.swift
//  ThePunch
//
//  Created by Valerie Williams on 10/20/25.
//

import SwiftUI

struct StatView: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.20))

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}
