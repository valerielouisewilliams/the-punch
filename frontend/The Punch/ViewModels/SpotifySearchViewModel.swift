//
//  SpotifySearchViewModel.swift
//  ThePunch
//
//  Created by Valerie Williams on 3/20/26.
//


import Foundation
import SwiftUI

@MainActor
final class SpotifySearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var tracks: [SpotifyTrack] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            tracks = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            tracks = try await SpotifyAPIService.shared.searchTracks(query: trimmed)
        } catch {
            appLog("Spotify search error: \(error)")
            errorMessage = "Could not search songs right now."
            tracks = []
        }

        isLoading = false
    }
}