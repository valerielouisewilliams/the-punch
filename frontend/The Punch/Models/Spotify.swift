//
//  Spotify.swift
//  ThePunch
//
//  Created by Valerie Williams on 3/20/26.
//

import Foundation

struct SpotifySearchResponse: Codable {
    let success: Bool?
    let message: String
    let count: Int
    let tracks: [SpotifyTrack]
}

struct SpotifyTrack: Codable, Identifiable, Hashable {
    let spotify_id: String
    let title: String
    let artist: String
    let album_image: String?
    let spotify_url: String?
    let preview_url: String?

    var id: String { spotify_id }
}
