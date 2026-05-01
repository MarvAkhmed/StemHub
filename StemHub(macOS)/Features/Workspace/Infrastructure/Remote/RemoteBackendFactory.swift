//
//  RemoteBackendFactory.swift
//  StemHub(macOS)
//
// Created by Marwa Awad on 27.04.2026.
//

import FirebaseFirestore
import Foundation

enum RemoteBackendKind {
    case firebase
}

struct RemoteRepositories {
    let bandRepository: BandRepository
    let projectRepository: ProjectRepository
    let userRepository: UserRepository
    let commentRepository: CommentRepository
    let versionRepository: VersionRepository
    let branchRepository: BranchRepository
    let remoteSnapshotRepository: RemoteSnapshotRepository
    let blobRepository: BlobRepository
    let commitRepository: CommitRepository
    let blobStorage: any RemoteFileTransferStrategy & RemoteBlobStorage & RemoteBlobByteCleaning
}

protocol RemoteRepositoryMaking {
    func makeRemoteRepositories() -> RemoteRepositories
}

struct RemoteBackendFactory: RemoteRepositoryMaking {
    let backendKind: RemoteBackendKind
    let db: Firestore
    
    func makeRemoteRepositories() -> RemoteRepositories {
        switch backendKind {
        case .firebase:
            return FirebaseRemoteRepositoryFactory().makeRemoteRepositories()
        }
    }
}

struct FirebaseRemoteRepositoryFactory: RemoteRepositoryMaking {
    func makeRemoteRepositories() -> RemoteRepositories {
        let firestore = Firestore.firestore()
        let blobStorage = FileUploadService()

        return RemoteRepositories(
            bandRepository: FirestoreBandRepository(db: firestore),
            projectRepository: FirestoreProjectRepository(db: firestore),
            userRepository: FirestoreUserRepository(db: firestore),
            commentRepository: FirestoreCommentRepository(db: firestore),
            versionRepository: FirestoreVersionRepository(db: firestore),
            branchRepository: FirestoreBranchRepository(db: firestore),
            remoteSnapshotRepository: FirestoreRemoteSnapshotRepository(db: firestore),
            blobRepository: FirestoreBlobRepository(db: firestore),
            commitRepository: FirestoreCommitRepository(db: firestore),
            blobStorage: blobStorage
        )
    }
}
