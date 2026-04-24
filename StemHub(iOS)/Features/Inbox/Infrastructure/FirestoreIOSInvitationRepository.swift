//
//  FirestoreIOSInvitationRepository.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import FirebaseFirestore

enum IOSInvitationDecision {
    case accept
    case decline
}

protocol IOSInvitationManaging {
    func fetchIncomingInvitations(for userID: String) async throws -> [IOSBandInvitation]
    func respond(
        to invitation: IOSBandInvitation,
        action: IOSInvitationDecision,
        currentUserID: String
    ) async throws
}

final class FirestoreIOSInvitationRepository: IOSInvitationManaging {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchIncomingInvitations(for userID: String) async throws -> [IOSBandInvitation] {
        let snapshot = try await db.collection("bandInvitations")
            .whereField("inviteeUserID", isEqualTo: userID)
            .getDocuments()

        return snapshot.documents
            .compactMap { $0.decoded(as: IOSBandInvitation.self) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func respond(
        to invitation: IOSBandInvitation,
        action: IOSInvitationDecision,
        currentUserID: String
    ) async throws {
        guard invitation.inviteeUserID == currentUserID else {
            throw IOSInvitationRepositoryError.unauthorized
        }

        switch action {
        case .accept:
            let batch = db.batch()
            let invitationReference = db.collection("bandInvitations").document(invitation.id)
            let bandReference = db.collection("bands").document(invitation.bandID)
            let userReference = db.collection("users").document(invitation.inviteeUserID)

            batch.updateData([
                "status": IOSBandInvitationStatus.accepted.rawValue,
                "respondedAt": Date()
            ], forDocument: invitationReference)
            batch.updateData([
                "memberIDs": FieldValue.arrayUnion([invitation.inviteeUserID])
            ], forDocument: bandReference)
            batch.updateData([
                "bandIDs": FieldValue.arrayUnion([invitation.bandID])
            ], forDocument: userReference)

            try await batch.commit()

        case .decline:
            try await db.collection("bandInvitations")
                .document(invitation.id)
                .updateData([
                    "status": IOSBandInvitationStatus.declined.rawValue,
                    "respondedAt": Date()
                ])
        }
    }
}

enum IOSInvitationRepositoryError: LocalizedError {
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Only the invited member can respond to this invitation."
        }
    }
}
