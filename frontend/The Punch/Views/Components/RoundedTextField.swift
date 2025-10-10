//
//  RoundedTextField.swift
//  The Punch
//
//  Created by Valerie Williams on 10/5/25.
//

import SwiftUI

struct RoundedTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white, lineWidth: 1)
            )
            .foregroundColor(.white)
            .autocapitalization(.none)
    }
}

struct RoundedSecureField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white, lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}
