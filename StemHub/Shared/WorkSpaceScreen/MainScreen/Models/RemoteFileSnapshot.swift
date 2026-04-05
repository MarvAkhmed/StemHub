//
//  RemoteFileSnapshot.swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation

struct RemoteFileSnapshot {
    let id: String
    let fileID: String
    let path: String
    let hash: String
    let versionID: String
    
    init(fileID: String, path: String, hash: String, versionID: String) {
        self.id = fileID
        self.fileID = fileID
        self.path = path
        self.hash = hash
        self.versionID = versionID
    }
}
