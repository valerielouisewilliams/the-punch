//
//  SoundManager.swift
//  ThePunch
//
//  Created by Valerie Williams on 12/1/25.
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?

    func playSound(_ sound: Sound) {
        guard let url = sound.url else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }

    enum Sound: String {
        case like = "like"
        case punch = "punch"
        case follow = "follow"
        case refresh = "refresh"
        case comment = "comment"

        var url: URL? {
            Bundle.main.url(forResource: rawValue, withExtension: "mp3")
        }
    }
}

