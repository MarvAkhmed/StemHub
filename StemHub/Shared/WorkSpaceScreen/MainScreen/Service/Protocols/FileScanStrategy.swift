//
//  FileScanStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol FileScanStrategy {
    func scan(folderURL: URL) throws -> [LocalFile]
    func makeLocalFile(from url: URL) -> LocalFile
}
