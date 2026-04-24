//
//  FirestoreBandInvitationRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import FirebaseFirestore
import Foundation

final class FirestoreBandInvitationRepository: BandInvitationRepository {
    private let db = Firestore.firestore()

    func fetchIncomingInvitations(for userID: String) async throws -> [BandInvitation] {
        let snapshot = try await db.collection("bandInvitations")
            .whereField("inviteeUserID", isEqualTo: userID)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: BandInvitation.self) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPendingInvitations(bandID: String) async throws -> [BandInvitation] {
        let snapshot = try await db.collection("bandInvitations")
            .whereField("bandID", isEqualTo: bandID)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: BandInvitation.self) }
            .filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchExistingPendingInvitation(
        bandID: String,
        inviteeUserID: String
    ) async throws -> BandInvitation? {
        let pendingInvitations = try await fetchPendingInvitations(bandID: bandID)
        return pendingInvitations.first { $0.inviteeUserID == inviteeUserID }
    }

    func createInvitation(_ invitation: BandInvitation) async throws {
        try db.collection("bandInvitations").document(invitation.id).setData(from: invitation)
    }

    func acceptInvitation(_ invitation: BandInvitation) async throws {
        let batch = db.batch()
        let invitationReference = db.collection("bandInvitations").document(invitation.id)
        let bandReference = db.collection("bands").document(invitation.bandID)
        let userReference = db.collection("users").document(invitation.inviteeUserID)

        batch.updateData([
            "status": BandInvitationStatus.accepted.rawValue,
            "respondedAt": Date()
        ], forDocument: invitationReference)
        batch.updateData([
            "memberIDs": FieldValue.arrayUnion([invitation.inviteeUserID])
        ], forDocument: bandReference)
        batch.updateData([
            "bandIDs": FieldValue.arrayUnion([invitation.bandID])
        ], forDocument: userReference)

        try await batch.commit()
    }

    func declineInvitation(_ invitation: BandInvitation) async throws {
        try await db.collection("bandInvitations")
            .document(invitation.id)
            .updateData([
                "status": BandInvitationStatus.declined.rawValue,
                "respondedAt": Date()
            ])
    }
}
