//
//  DiffResult.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct DiffResult {
    let added: [LocalFile]
    let removed: [RemoteFileSnapshot]
    let modified: [(local: LocalFile, remote: RemoteFileSnapshot)]
}
