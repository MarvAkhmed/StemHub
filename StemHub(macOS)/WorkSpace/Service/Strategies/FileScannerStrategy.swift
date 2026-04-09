//
//  FileScannerStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation

protocol FileScannerStrategy {
    func scan(folderURL: URL) throws -> [LocalFile]
}

struct DefaultFileScannerStrategy: FileScannerStrategy {
    private let scanner = LocalFileScanner()
    
    func scan(folderURL: URL) throws -> [LocalFile] {
        try scanner.scan(folderURL: folderURL)
    }
}
