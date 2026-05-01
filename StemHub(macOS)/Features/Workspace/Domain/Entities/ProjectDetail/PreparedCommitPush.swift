//
//  PreparedCommitPush.swift
//  StemHub(macOS)
//
// Created by Marwa Awad on 27.04.2026.
//

import Foundation

struct PreparedCommitPush: Sendable {
    let commit: Commit
    let expectedParentVersionID: String?
    let projectVersion: ProjectVersion
    let fileVersionsToSave: [FileVersion]
    let blobsToSave: [FileBlob]
}
