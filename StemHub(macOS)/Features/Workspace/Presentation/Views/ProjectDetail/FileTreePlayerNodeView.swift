//
//  FileTreePlayerNodeView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import SwiftUI


// MARK: - File Tree Player Node View
struct FileTreePlayerNodeView: View {
    let node: FileTreeNode
    @ObservedObject var audioDeckViewModel: MultiStemPlaybackViewModel
    @Binding var selectedFileURL: URL?
    
    var body: some View {
        if node.isDirectory {
            DisclosureGroup {
                ForEach(node.children ?? []) { childNode in
                    FileTreePlayerNodeView(
                        node: childNode,
                        audioDeckViewModel: audioDeckViewModel,
                        selectedFileURL: $selectedFileURL
                    )
                        .padding(.leading, 16)
                }
            } label: {
                Label(node.url.lastPathComponent, systemImage: "folder")
                    .font(.body)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    selectedFileURL = node.url
                }) {
                    Label(node.url.lastPathComponent, systemImage: iconForFile(node.url))
                        .font(.body)
                        .foregroundColor(selectedFileURL == node.url ? .accentColor : .primary)
                }
                .buttonStyle(PlainButtonStyle())

                if isAudioFile(node.url) {
                    HStack(spacing: 10) {
                        Button(action: {
                            audioDeckViewModel.togglePlayback(for: node.url)
                        }) {
                            Label(
                                audioDeckViewModel.isPlaying(node.url) ? "Pause" : "Play",
                                systemImage: audioDeckViewModel.isPlaying(node.url) ? "pause.circle.fill" : "play.circle.fill"
                            )
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            audioDeckViewModel.toggleSelection(for: node.url)
                        }) {
                            Label(
                                audioDeckViewModel.isSelected(node.url) ? "Selected" : "Select",
                                systemImage: audioDeckViewModel.isSelected(node.url) ? "checkmark.circle.fill" : "circle"
                            )
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Text("Stem preview")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 26)
                }
            }
        }
    }
    
    private func iconForFile(_ url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp3", "wav", "aiff", "m4a":
            return "music.note"
        case "mid", "midi":
            return "pianokeys"
        default:
            return "doc"
        }
    }

    private func isAudioFile(_ url: URL) -> Bool {
        ["mp3", "wav", "aiff", "m4a", "aac", "caf"].contains(url.pathExtension.lowercased())
    }
}

//struct FileTreePlayerNodeView: View {
//    let node: FileTreeNode
//    @State private var isExpanded: Bool = true
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Folder or file row
//            HStack(spacing: 4) {
//                if node.isDirectory {
//                    Image(systemName: "folder")
//                        .foregroundColor(.accentColor)
//                    // Add chevron for expansion
//                    Image(systemName: isExpanded ? "folder.fill" : "folder")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .onTapGesture {
//                            withAnimation(.easeInOut(duration: 0.2)) {
//                                isExpanded.toggle()
//                            }
//                        }
//                } else {
//                    Image(systemName: iconForFile(url: node.url))
//                        .foregroundColor(.accentColor)
//                        .frame(width: 20)
//                }
//                
//                Text(node.name)
//                    .font(.system(.body, design: .monospaced))
//                    .lineLimit(1)
//                    .truncationMode(.middle)
//                
//                Spacer()
//            }
//            .padding(.vertical, 4)
//            
//            // For audio files: show inline player
//            if !node.isDirectory && isAudioFile(url: node.url) {
//                AudioPlayerView(url: node.url)
//                    .padding(.leading, 24)
//                    .padding(.bottom, 4)
//            }
//            
//            // Children (recursive)
//            if node.isDirectory && isExpanded, let children = node.children {
//                VStack(alignment: .leading, spacing: 0) {
//                    ForEach(children) { child in
//                        FileTreePlayerNodeView(node: child)
//                            .padding(.leading, 16)
//                    }
//                }
//            }
//        }
//    }
//    
//    private func iconForFile(url: URL) -> String {
//        let ext = url.pathExtension.lowercased()
//        switch ext {
//        case "mp3", "wav", "aac", "m4a", "flac", "ogg", "aiff":
//            return "music.note"
//        case "mid", "midi":
//            return "pianokeys"
//        case "url":
//            return "link"
//        case "txt", "md", "rtf":
//            return "doc.text"
//        default:
//            return "doc"
//        }
//    }
//    
//    private func isAudioFile(url: URL) -> Bool {
//        let ext = url.pathExtension.lowercased()
//        return ["mp3", "wav", "aac", "m4a", "flac", "ogg", "aiff"].contains(ext)
//    }
//}
