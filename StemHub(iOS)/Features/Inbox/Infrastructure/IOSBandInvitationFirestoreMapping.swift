//
//  IOSBandInvitationFirestoreMapping.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

extension IOSBandInvitation: IOSFirestoreDocumentConvertible {
    init?(documentID: String, data: [String: Any]) {
        guard
            let status = IOSBandInvitationStatus(rawValue: data.string("status", default: IOSBandInvitationStatus.pending.rawValue))
        else {
            return nil
        }

        self.init(
            id: documentID,
            bandID: data.string("bandID"),
            bandName: data.string("bandName", default: "Band"),
            inviteeUserID: data.string("inviteeUserID"),
            inviteeEmail: data.string("inviteeEmail"),
            requestedByUserID: data.string("requestedByUserID"),
            requestedByName: data["requestedByName"] as? String,
            status: status,
            createdAt: data.date("createdAt"),
            respondedAt: data.optionalDate("respondedAt")
        )
    }
}
