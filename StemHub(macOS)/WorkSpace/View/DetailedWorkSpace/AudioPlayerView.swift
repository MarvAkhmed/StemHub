//
//  AudioPlayerView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI
import AVFoundation
//
//struct AudioPlayerView: View {
//    let url: URL
//    @State private var player: AVAudioPlayer?
//    @State private var isPlaying = false
//    @State private var isAccessGranted = false
//    
//    var body: some View {
//        HStack {
//            Button(action: togglePlayback) {
//                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                    .font(.largeTitle)
//            }
//            .buttonStyle(PlainButtonStyle())
//            
//            Text(url.lastPathComponent)
//                .lineLimit(1)
//                .font(.caption)
//        }
//        .onDisappear {
//            player?.stop()
//            if isAccessGranted {
//                url.stopAccessingSecurityScopedResource()
//                isAccessGranted = false
//            }
//        }
//    }
//    
//    private func togglePlayback() {
//        if isPlaying {
//            player?.pause()
//            isPlaying = false
//        } else {
//            if !isAccessGranted {
//                isAccessGranted = url.startAccessingSecurityScopedResource()
//            }
//            if player == nil {
//                do {
//                    player = try AVAudioPlayer(contentsOf: url)
//                    player?.prepareToPlay()
//                } catch {
//                    print("Cannot play audio: \(error)")
//                    return
//                }
//            }
//            player?.play()
//            isPlaying = true
//        }
//    }
//}


// MARK: - Audio Player View (optional)
struct AudioPlayerView: View {
    let url: URL
    
    var body: some View {
        VStack {
            Text(url.lastPathComponent)
                .font(.headline)
                .padding()
            
            // Simple audio player placeholder
            // In a real implementation, use AVPlayer
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                Image(systemName: "pause.circle.fill")
                    .font(.largeTitle)
                Image(systemName: "stop.circle.fill")
                    .font(.largeTitle)
            }
            .padding()
            
            Text("Audio player would go here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}
