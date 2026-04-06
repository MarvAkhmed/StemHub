//
//  FileTreeView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import SwiftUI


struct FileTreeView: View {
    let nodes: [FileTreeNode]
    @Binding var selectedFileURL: URL?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(nodes) { node in
                    FileTreeNodeView(node: node, selectedFileURL: $selectedFileURL)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FileTreeNodeView: View {
    let node: FileTreeNode
    @Binding var selectedFileURL: URL?
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                if node.isDirectory {
                    Image(systemName: isExpanded ? "folder.open" : "folder")
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }
                } else {
                    Image(systemName: iconForFile(url: node.url))
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                }
                
                Text(node.name)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(selectedFileURL == node.url ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
            .onTapGesture {
                if !node.isDirectory {
                    selectedFileURL = node.url
                }
            }
            
            if node.isDirectory && isExpanded, let children = node.children {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(children) { child in
                        FileTreeNodeView(node: child, selectedFileURL: $selectedFileURL)
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
    
    private func iconForFile(url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp3", "wav", "aac", "m4a", "flac", "ogg", "aiff":
            return "music.note"
        case "mid", "midi":
            return "pianokeys"
        case "url":
            return "link"
        case "txt", "md", "rtf":
            return "doc.text"
        default:
            return "doc"
        }
    }
}
