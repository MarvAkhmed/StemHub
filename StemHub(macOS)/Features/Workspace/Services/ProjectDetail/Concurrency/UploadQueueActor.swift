//
//  UploadQueueActor.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

actor UploadQueueActor<UploadResult: Sendable> {
    private var completedUploads: [String: UploadResult] = [:]
    private var inFlightUploads: [String: Task<UploadResult, Error>] = [:]

    func upload(
        blobID: String,
        createTask: @Sendable @escaping () -> Task<UploadResult, Error>
    ) async throws -> UploadResult {
        if let completed = completedUploads[blobID] {
            return completed
        }

        if let task = inFlightUploads[blobID] {
            return try await task.value
        }

        let task = createTask()
        inFlightUploads[blobID] = task

        do {
            let result = try await task.value
            completedUploads[blobID] = result
            inFlightUploads[blobID] = nil
            return result
        } catch {
            inFlightUploads[blobID] = nil
            throw error
        }
    }
}
