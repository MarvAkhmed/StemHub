//
//  FileManager.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

extension FileManager {
    func hasWritePermission(atPath path: String) -> Bool {
        #if canImport(Darwin)
        return access(path, W_OK) == 0
        #else
        return self.isWritableFile(atPath: path) // now calling the original method
        #endif
    }
}
