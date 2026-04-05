//
//  FileUploadStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol FileUploadStrategy {
    func uploadFile(localURL: URL, blobID: String) async throws -> String
    func downloadFile(storagePath: String, to localURL: URL) async throws
}
