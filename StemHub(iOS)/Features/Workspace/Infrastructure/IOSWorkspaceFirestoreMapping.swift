//
//  IOSWorkspaceFirestoreMapping.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

extension IOSBandSummary: IOSFirestoreDocumentConvertible {
    init?(documentID: String, data: [String: Any]) {
        let memberIDs = data.stringArray("memberIDs")

        self.init(
            id: documentID,
            name: data.string("name", default: "Band"),
            adminUserID: data.string("adminUserID", default: memberIDs.first ?? ""),
            memberIDs: memberIDs,
            projectIDs: data.stringArray("projectIDs"),
            createdAt: data.date("createdAt")
        )
    }
}

extension IOSProjectSummary: IOSFirestoreDocumentConvertible {
    init?(documentID: String, data: [String: Any]) {
        let createdAt = data.date("createdAt")

        self.init(
            id: documentID,
            name: data.string("name", default: "Untitled Project"),
            bandID: data.string("bandID"),
            createdBy: data.string("createdBy"),
            currentBranchID: data.string("currentBranchID"),
            currentVersionID: data.string("currentVersionID"),
            createdAt: createdAt,
            updatedAt: data.date("updatedAt", default: createdAt),
            posterBase64: data["posterBase64"] as? String
        )
    }
}
