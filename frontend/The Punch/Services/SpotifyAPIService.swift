//
//  SpotifyAPIService.swift
//  ThePunch
//
//  Created by Valerie Williams on 3/20/26.
//


import Foundation

final class SpotifyAPIService {
    static let shared = SpotifyAPIService()

    private init() {}

    func searchTracks(query: String) async throws -> [SpotifyTrack] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        guard let url = URL(string: "https://api.thepunchapp.com/api/spotify/search?q=\(encodedQuery)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            appLog("Spotify search failed with status \(httpResponse.statusCode): \(body)")
            throw URLError(.badServerResponse)
        }
        
        let raw = String(data: data, encoding: .utf8) ?? "Could not decode raw response"
        appLog("RAW SPOTIFY RESPONSE:", raw)
        
        let decoded = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        return decoded.tracks
    }
}
