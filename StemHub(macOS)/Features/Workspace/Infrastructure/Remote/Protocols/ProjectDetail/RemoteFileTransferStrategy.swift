//
//  RemoteFileTransferStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

protocol RemoteFileTransfering: Sendable {
    func uploadFile(localURL: URL, storagePath: String) async throws -> String
    func downloadFile(storagePath: String, to localURL: URL) async throws
}

protocol RemoteBlobStorage: Sendable {
    func upload(data: Data, to path: String) async throws -> URL
    func download(from path: String) async throws -> Data
    func delete(path: String) async throws
}

protocol RemoteFileTransferStrategy: RemoteFileTransfering {}
