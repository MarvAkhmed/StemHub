//
//  FirestoreCommitRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import FirebaseFirestore
import Foundation

final class FirestoreCommitRepository: CommitRepository, @unchecked Sendable {

    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func persistCommitPush(_ push: PreparedCommitPush, branchID: String) async throws -> ProjectVersion {
        try await runPushTransaction(push, branchID: branchID)
        return push.projectVersion
    }
}

private enum FirestoreCommitPushTransactionErrorCode: Int {
    case branchNotFound = 1
    case outdatedCommit = 2
}

private let firestoreCommitPushTransactionErrorDomain = "StemHub.FirestoreCommitRepository.PushTransaction"

private extension FirestoreCommitRepository {
    func runPushTransaction(
        _ push: PreparedCommitPush,
        branchID: String
    ) async throws {
        let branchRef = db.collection(FirestoreCollections.branches.path).document(branchID)
        let blobsCollection = db.collection(FirestoreCollections.blobs.path)
        let fileVersionsCollection = db.collection(FirestoreCollections.fileVersions.path)
        let commitRef = db.collection(FirestoreCollections.commits.path).document(push.commit.id)
        let projectVersionRef = db.collection(FirestoreCollections.projectVersions.path)
            .document(push.projectVersion.id)

        do {
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let branchDocument = try transaction.getDocument(branchRef)
                    guard branchDocument.exists else {
                        errorPointer?.pointee = self.pushTransactionError(.branchNotFound)
                        return nil
                    }

                    let branch = try branchDocument.data(as: Branch.self)
                    guard push.commit.basedOnVersionID == (branch.headVersionID ?? "") else {
                        errorPointer?.pointee = self.pushTransactionError(.outdatedCommit)
                        return nil
                    }

                    for blob in push.blobsToSave {
                        try transaction.setData(
                            from: blob,
                            forDocument: blobsCollection.document(blob.id)
                        )
                    }

                    for fileVersion in push.fileVersionsToSave {
                        try transaction.setData(
                            from: fileVersion,
                            forDocument: fileVersionsCollection.document(fileVersion.id)
                        )
                    }

                    try transaction.setData(from: push.commit, forDocument: commitRef)
                    try transaction.setData(from: push.projectVersion, forDocument: projectVersionRef)
                    transaction.updateData(
                        [FirestoreField.headVersionID.path: push.projectVersion.id],
                        forDocument: branchRef
                    )

                    return push.projectVersion.id
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
        } catch {
            throw normalizedPushTransactionError(error)
        }
    }

    func pushTransactionError(_ code: FirestoreCommitPushTransactionErrorCode) -> NSError {
        NSError(
            domain: firestoreCommitPushTransactionErrorDomain,
            code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: pushTransactionErrorDescription(for: code)]
        )
    }

    func pushTransactionErrorDescription(for code: FirestoreCommitPushTransactionErrorCode) -> String {
        switch code {
        case .branchNotFound:
            return SyncError.branchNotFound.localizedDescription
        case .outdatedCommit:
            return SyncError.outdatedCommit.localizedDescription
        }
    }

    func normalizedPushTransactionError(_ error: Error) -> Error {
        let nsError = error as NSError
        guard nsError.domain == firestoreCommitPushTransactionErrorDomain,
              let code = FirestoreCommitPushTransactionErrorCode(rawValue: nsError.code) else {
            return error
        }

        switch code {
        case .branchNotFound:
            return SyncError.branchNotFound
        case .outdatedCommit:
            return SyncError.outdatedCommit
        }
    }
}
