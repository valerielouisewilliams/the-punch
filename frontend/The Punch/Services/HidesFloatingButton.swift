//
//  HidesFloatingButton.swift
//  ThePunch
//
//  Created by Valerie Williams on 11/6/25.
//

import SwiftUI

struct HidesFloatingButton: ViewModifier {
    @EnvironmentObject var uiState: UIState

    func body(content: Content) -> some View {
        content
            .onAppear { withAnimation(.easeOut(duration: 0.15)) { uiState.showFloatingButton = false } }
            .onDisappear { withAnimation(.easeIn(duration: 0.15)) { uiState.showFloatingButton = true } }
    }
}

extension View {
    func hidesFloatingButton() -> some View { modifier(HidesFloatingButton()) }
}
