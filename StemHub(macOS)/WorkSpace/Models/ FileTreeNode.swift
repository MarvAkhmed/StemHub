//
//   FileTreeNode.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct FileTreeNode: Identifiable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    let isDirectory: Bool
    var children: [FileTreeNode]?   
}
