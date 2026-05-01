//
//  ProjectDetailCommentsState.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectDetailCommentsState {
    var selectedFileComments: [Comment] = []
    var versionComments: [Comment] = []
    var commentsByFileID: [String: [Comment]] = [:]
    var commentMarkersByFileID: [String: [CommentMarker]] = [:]
    var activeCommentAtPlaybackTime: Comment?
    var loadedCommentsVersionID: String?
    var loadedVersionID: String?
    var newCommentText = ""
    var draftCommentText = ""
    var pendingCommentTimestampSeconds: Double?
    var isCommentComposerPresented = false
    var selectedCommentID: String?
}
