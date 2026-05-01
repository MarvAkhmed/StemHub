//
//  CommentMarker.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct CommentMarker: Identifiable, Sendable {
    let id: String
    let commentID: String
    let fileID: String
    let timestampSeconds: Double
    let position: Double
    let previewText: String
}
