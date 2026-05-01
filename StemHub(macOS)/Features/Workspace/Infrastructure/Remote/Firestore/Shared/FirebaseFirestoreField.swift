//
//  FirebaseFirestoreField.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

enum FirestoreField: String {
    case id
    case name
    case email
    case displayName
    case createdAt
    case updatedAt

    case userID
    case bandID
    case bandIDs
    case projectID
    case projectIDs
    case branchID
    case currentBranchID
    case currentVersionID
    case headVersionID
    case versionID
    case parentVersionID
    case fileID
    case filePath
    case fileVersionIDs
    case blobID
    case commitID = "commitId"
    case memberIDs
    case adminUserIDs
    case approvedByUserID

    case posterBase64
    case approvalState
    case approvedAt
    case reviewState
    case isHiddenFromTimeline

    var path: String {
        rawValue
    }
}
