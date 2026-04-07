//
//  AudioPlayerView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let url: URL
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var isAccessGranted = false
    
    var body: some View {
        HStack {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(url.lastPathComponent)
                .lineLimit(1)
                .font(.caption)
        }
        .onDisappear {
            player?.stop()
            if isAccessGranted {
                url.stopAccessingSecurityScopedResource()
                isAccessGranted = false
            }
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            if !isAccessGranted {
                isAccessGranted = url.startAccessingSecurityScopedResource()
            }
            if player == nil {
                do {
                    player = try AVAudioPlayer(contentsOf: url)
                    player?.prepareToPlay()
                } catch {
                    print("Cannot play audio: \(error)")
                    return
                }
            }
            player?.play()
            isPlaying = true
        }
    }
}
