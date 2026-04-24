//
//  IOSProjectVersionFirestoreMapping.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

struct IOSProjectVersionRecord: Identifiable, Hashable, Sendable {
    let id: String
    let projectID: String
    let versionNumber: Int
    let createdAt: Date
    let approvalState: String
}

extension IOSProjectVersionRecord: IOSFirestoreDocumentConvertible {
    init?(documentID: String, data: [String: Any]) {
        self.init(
            id: documentID,
            projectID: data.string("projectID"),
            versionNumber: data.int("versionNumber"),
            createdAt: data.date("createdAt"),
            approvalState: data.string("approvalState", default: "pending")
        )
    }
}
