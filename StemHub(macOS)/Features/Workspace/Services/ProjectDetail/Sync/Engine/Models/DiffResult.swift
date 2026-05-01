//
//  DiffResult.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import Foundation

struct DiffResult {
    let added: [LocalFile]
    let removed: [RemoteFileSnapshot]
    let modified: [(local: LocalFile, remote: RemoteFileSnapshot)]

    nonisolated var hasChanges: Bool {
        !added.isEmpty || !removed.isEmpty || !modified.isEmpty
    }
}
