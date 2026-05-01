//
//  ProjectDetailViewModel+CommentsAndReview.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

extension ProjectDetailViewModel {
    func sendBandInvite() async {
        guard let currentUserID else {
            ui.errorMessage = ProjectDetailError.userNotSignedIn.localizedDescription
            return
        }

        let email = ui.inviteMemberEmail.trimmed

        await performActivity(.invitingMember) {
            collaboration.pendingInvitations = try await dependencies.collaborationService.inviteMember(
                email: email,
                bandID: project.bandID,
                bandName: collaboration.band?.name ?? projectSubtitle,
                requestedBy: currentUserID
            )
            ui.inviteMemberEmail = ""
        }
    }

    func addComment() async {
        guard let currentUserID else {
            ui.errorMessage = ProjectDetailError.userNotSignedIn.localizedDescription
            return
        }

        guard let currentBranch = resolvedBranch else {
            ui.errorMessage = ProjectDetailError.missingBranch.localizedDescription
            return
        }

        guard let path = selection.selectedFilePath else {
            ui.errorMessage = ProjectDetailError.missingSelectedFile.localizedDescription
            return
        }

        guard let versionID = activeCommentVersionID else {
            ui.errorMessage = ProjectDetailError.missingVersionContext.localizedDescription
            return
        }

        let commentText = comments.newCommentText.trimmed
        let timestamp = selectedFileSupportsTimestamp ? selection.selectedCommentTimestamp : nil

        await performActivity(.savingComment) {
            try await dependencies.commentWorkflowService.addComment(ProjectCommentDraftInput(
                projectID: project.id,
                branchID: currentBranch.id,
                versionID: versionID,
                filePath: path,
                text: commentText,
                timestamp: timestamp,
                userID: currentUserID
            ))

            comments.newCommentText = ""
            try await refreshComments(forceRefresh: true)
        }
    }

    func addCommentAtCurrentTime(fileID: String) {
        comments.pendingCommentTimestampSeconds = selection.selectedCommentTimestamp ?? 0
        comments.draftCommentText = ""
        comments.isCommentComposerPresented = true
        comments.selectedCommentID = nil
    }

    func saveDraftTimestampedComment(fileID: String) async {
        guard let currentUserID else {
            ui.errorMessage = ProjectDetailError.userNotSignedIn.localizedDescription
            return
        }

        guard let currentBranch = resolvedBranch else {
            ui.errorMessage = ProjectDetailError.missingBranch.localizedDescription
            return
        }

        guard let versionID = activeCommentVersionID else {
            ui.errorMessage = ProjectDetailError.missingVersionContext.localizedDescription
            return
        }

        guard let filePath = selection.selectedFilePath else {
            ui.errorMessage = ProjectDetailError.missingSelectedFile.localizedDescription
            return
        }

        let timestamp = comments.pendingCommentTimestampSeconds ?? selection.selectedCommentTimestamp ?? 0
        let text = comments.draftCommentText

        await performActivity(.savingComment) {
            let savedComment = try await dependencies.timestampedCommentService.addComment(
                context: TimestampedCommentContext(
                    projectID: project.id,
                    branchID: currentBranch.id,
                    versionID: versionID,
                    fileID: fileID,
                    filePath: filePath,
                    userID: currentUserID
                ),
                timestampSeconds: timestamp,
                text: text
            )

            comments.draftCommentText = ""
            comments.pendingCommentTimestampSeconds = nil
            comments.isCommentComposerPresented = false
            comments.selectedCommentID = savedComment.id
            try await refreshComments(forceRefresh: true)
        }
    }

    func deleteTimestampedComment(_ comment: Comment) async {
        await performActivity(.savingComment) {
            try await dependencies.timestampedCommentService.deleteComment(comment)
            try await refreshComments(forceRefresh: true)
        }
    }

    func resolveTimestampedComment(_ comment: Comment) async {
        await performActivity(.savingComment) {
            _ = try await dependencies.timestampedCommentService.resolveComment(comment)
            try await refreshComments(forceRefresh: true)
        }
    }

    func seekToComment(_ comment: Comment) async {
        selection.selectedCommentTimestamp = comment.timestamp
        await focus(on: comment)
    }

    func updateActiveCommentAtPlaybackTime(
        fileID: String,
        timestampSeconds: Double,
        tolerance: Double = 0.25
    ) {
        let commentsForFile = comments.commentsByFileID[fileID] ?? comments.selectedFileComments
        comments.activeCommentAtPlaybackTime = dependencies.timestampedCommentService.commentsNear(
            timestampSeconds: timestampSeconds,
            fileID: fileID,
            comments: commentsForFile,
            tolerance: tolerance
        ).first
    }

    func setCommentReviewState(
        _ state: CommentReviewState,
        for comment: Comment
    ) async {
        await performActivity(.savingComment) {
            try await dependencies.commentWorkflowService.updateCommentReview(
                commentID: comment.id,
                state: state
            )
            try await refreshComments(forceRefresh: true)
        }
    }

    func focus(on comment: Comment) async {
        selection.selectedFilePath = comment.filePath
        selection.selectedCommentTimestamp = comment.timestamp
        await restoreSelectedFileSelection()
        refreshSelectedFileComments()
    }

    func authorName(for userID: String) -> String {
        collaboration.members.displayName(for: userID)
    }

    func approveSelectedVersion() async {
        guard
            let currentUserID,
            let selectedVersion = workspace.selectedVersion,
            isCurrentUserAdmin
        else {
            ui.errorMessage = "Only the band admin can approve versions."
            return
        }

        await performActivity(.approvingVersion) {
            try await dependencies.versionWorkflowService.approveVersion(
                versionID: selectedVersion.id,
                approvedBy: currentUserID
            )
            try await refreshWorkspaceState(
                preserveSelectedVersionID: selectedVersion.id,
                includeCollaborationData: false
            )
        }
    }

    func refreshComments(forceRefresh: Bool) async throws {
        guard let versionID = activeCommentVersionID else {
            applyCommentSnapshot(
                ProjectCommentsSnapshot(
                    versionID: nil,
                    versionComments: [],
                    selectedFileComments: []
                )
            )
            return
        }

        if forceRefresh || comments.loadedCommentsVersionID != versionID {
            applyCommentSnapshot(
                try await dependencies.commentWorkflowService.loadComments(
                    versionID: versionID,
                    selectedFilePath: selection.selectedFilePath
                )
            )
        } else {
            refreshSelectedFileComments()
        }
    }

    func refreshSelectedFileComments() {
        guard selection.selectedFilePath != nil else {
            comments.selectedFileComments = []
            selection.selectedCommentTimestamp = nil
            return
        }

        comments.selectedFileComments = dependencies.commentWorkflowService.selectedFileComments(
            from: comments.versionComments,
            selectedFilePath: selection.selectedFilePath
        )
        rebuildTimestampedCommentState()
    }

    func applyCommentSnapshot(_ snapshot: ProjectCommentsSnapshot) {
        comments.versionComments = snapshot.versionComments
        comments.selectedFileComments = snapshot.selectedFileComments
        comments.loadedCommentsVersionID = snapshot.versionID
        rebuildTimestampedCommentState()
    }

    func rebuildTimestampedCommentState() {
        let groupedComments = Dictionary(
            grouping: comments.versionComments,
            by: { $0.fileID ?? $0.filePath }
        )

        comments.commentsByFileID = groupedComments
        comments.commentMarkersByFileID = groupedComments.mapValues { fileComments in
            dependencies.commentWorkflowService.commentMarkers(
                from: fileComments,
                fileID: fileComments.first?.fileID ?? fileComments.first?.filePath ?? "",
                duration: 1
            )
        }
    }
}
