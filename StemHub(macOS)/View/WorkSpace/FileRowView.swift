//
//  FileRowView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI


struct FileRowView: View {
    let file: MusicFile
    
    var body: some View {
        HStack {
            Image(systemName: fileIcon(for: file))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body)
                
                if !file.path.isEmpty {
                    Text(file.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(file.fileExtension.uppercased())
                .font(.caption)
                .padding(4)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - File Icon Helper
    private func fileIcon(for file: MusicFile) -> String {
        let ext = file.fileExtension.lowercased()
        
        switch ext {
        case "mp3", "wav", "aac", "m4a", "flac", "ogg":
            return "music.note"
        case "mid", "midi":
            return "pianokeys"
        case "pdf", "txt", "md":
            return "doc.text"
        case "zip", "rar":
            return "archivebox"
        default:
            return "doc"
        }
    }
}
