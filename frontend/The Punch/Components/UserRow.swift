//
//  UserRow.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(user.isFriend ? "friend" : "not friend")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
