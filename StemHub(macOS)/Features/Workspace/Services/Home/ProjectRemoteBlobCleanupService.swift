//
//  ProjectRemoteBlobCleanupService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 30.04.2026.
//

import Foundation

struct ProjectRemoteBlobCleanupPlan {
    let storagePaths: [String]
}

protocol ProjectRemoteBlobCleaning {
    func makeCleanupPlan(for projectID: String, bandID: String) async throws -> ProjectRemoteBlobCleanupPlan 
    func cleanupBlobs(using plan: ProjectRemoteBlobCleanupPlan) async throws
}

final class ProjectRemoteBlobCleanupService: ProjectRemoteBlobCleaning {
    private let blobStoragePathListing: any ProjectBlobStoragePathListing
    private let blobByteCleaner: any RemoteBlobByteCleaning

    init(
        blobStoragePathListing: any ProjectBlobStoragePathListing,
        blobByteCleaner: any RemoteBlobByteCleaning
    ) {
        self.blobStoragePathListing = blobStoragePathListing
        self.blobByteCleaner = blobByteCleaner
    }

    func makeCleanupPlan(for projectID: String, bandID: String) async throws -> ProjectRemoteBlobCleanupPlan {
        let storagePaths = try await blobStoragePathListing.fetchBlobStoragePaths(projectID: projectID, bandID: bandID)
        return ProjectRemoteBlobCleanupPlan(storagePaths: storagePaths)
    }

    func cleanupBlobs(using plan: ProjectRemoteBlobCleanupPlan) async throws {
        try await blobByteCleaner.deleteBlobBytes(storagePaths: plan.storagePaths)
    }
}
