//
//  PunchButtonViewModel.swift
//  ThePunch
//
//  Created by Valerie Williams on 3/23/26.
//


import Foundation
import SwiftUI

@MainActor
final class PunchButtonViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var didSend = false
    @Published var errorMessage: String?
    
    func sendPunch(to userId: Int) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await PunchService.shared.sendPunch(to: userId)
            didSend = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            didSend = false
        } catch {
            errorMessage = error.localizedDescription
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        isLoading = false
    }
}