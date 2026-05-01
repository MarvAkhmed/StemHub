//
//  ProjectDetailViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import AppKit
import Combine
import Foundation

@MainActor
final class ProjectDetailViewModel: ObservableObject {

    // MARK: - Dependency
    let dependencies: ProjectDetailViewModelDependencies

    // MARK: - State
    @Published var project: Project
    @Published var workspace = ProjectDetailWorkspaceState()
    @Published var collaboration = ProjectDetailCollaborationState()
    @Published var selection = ProjectDetailSelectionState()
    @Published var comments = ProjectDetailCommentsState()
    @Published var ui = ProjectDetailUIState()

    var hasLoadedInitialState = false

    // MARK: - View API
    var isLoading: Bool { ui.activityState.isLoading }
    var projectName: String { project.name }
    var projectSubtitle: String { collaboration.band?.name ?? "Collaborative project workspace" }
    var projectPosterImage: NSImage? { dependencies.projectPosterService.image(from: project.posterBase64) }
    var audioPlaybackPreparer: AudioPlaybackPreparing { dependencies.audioPlaybackPreparer }
    var defaultPlaybackRate: Double { dependencies.defaultPlaybackRate }

    var band: Band? { collaboration.band }
    var branches: [Branch] { workspace.branches }
    var currentBranch: Branch? { resolvedBranch }
    var versionHistory: [ProjectVersion] { workspace.versionHistory }
    var selectedVersion: ProjectVersion? { workspace.selectedVersion }
    var versionDiff: ProjectDiff? { workspace.versionDiff }
    var fileTree: [FileTreeNode] { workspace.fileTree }
    var members: [User] { collaboration.members }
    var pendingInvitations: [BandInvitation] { collaboration.pendingInvitations }
    var localCommits: [LocalCommit] { workspace.localCommits }
    var selectedFileComments: [Comment] { comments.selectedFileComments }
    var versionComments: [Comment] { comments.versionComments }

    var selectedFileURL: URL? {
        get { selection.selectedFileURL }
        set { selection.selectedFileURL = newValue }
    }

    var selectedFilePath: String? {
        get { selection.selectedFilePath }
        set { selection.selectedFilePath = newValue }
    }

    var selectedCommentTimestamp: Double? {
        get { selection.selectedCommentTimestamp }
        set { selection.selectedCommentTimestamp = newValue }
    }

    var midiEditorSession: ProjectMIDISession? {
        get { selection.midiEditorSession }
        set { selection.midiEditorSession = newValue }
    }

    var newBranchName: String {
        get { ui.newBranchName }
        set { ui.newBranchName = newValue }
    }

    var inviteMemberEmail: String {
        get { ui.inviteMemberEmail }
        set { ui.inviteMemberEmail = newValue }
    }

    var newCommentText: String {
        get { comments.newCommentText }
        set { comments.newCommentText = newValue }
    }

    var errorMessage: String? {
        get { ui.errorMessage }
        set { ui.errorMessage = newValue }
    }

    var showRelocationAlert: Bool {
        get { ui.showRelocationAlert }
        set { ui.showRelocationAlert = newValue }
    }

    var currentVersionID: String { currentHeadVersionID.orEmpty }
    var currentVersionNumber: String { workspace.versionHistory.versionNumberText() }
    var currentVersionTitle: String { workspace.versionHistory.versionTitle() }
    var currentBranchName: String { resolvedBranch?.name ?? "main" }
    var workspaceTitle: String { workspace.selectedVersion?.reviewTitle ?? "Working Copy" }
    var workspaceSubtitle: String {
        workspace.selectedVersion?.formattedCreatedAt ?? "Live branch workspace with local edits and pending commits."
    }
    var selectedVersionStatusTitle: String {
        workspace.selectedVersion?.approvalState.title ?? "Working Copy"
    }
    var selectedFileDisplayName: String { selection.selectedFilePath.fileDisplayName }
    var selectedCommentTimestampLabel: String {
        selection.selectedCommentTimestamp?.formattedTimestamp() ?? "No timestamp selected"
    }

    var canCommit: Bool { workspace.currentBranch != nil && currentUserID != nil }
    var canCreateBranch: Bool { !ui.newBranchName.trimmed.isEmpty && currentUserID != nil }
    var canInviteMember: Bool { isCurrentUserAdmin && !ui.inviteMemberEmail.trimmed.isEmpty }
    var canApproveSelectedVersion: Bool {
        isCurrentUserAdmin && workspace.selectedVersion?.approvalState == .pendingReview
    }
    var canAddComment: Bool {
        !comments.newCommentText.trimmed.isEmpty &&
        selection.selectedFilePath != nil &&
        activeCommentVersionID != nil &&
        workspace.currentBranch != nil
    }
    var pendingCommitCount: Int { workspace.localCommits.count }
    var isCurrentUserAdmin: Bool {
        guard let currentUserID, let band = collaboration.band else { return false }
        return band.isAdmin(userID: currentUserID)
    }

    var selectedFileIsMIDI: Bool {
        guard let path = selection.selectedFilePath else { return false }
        return dependencies.fileTypeProvider.isMIDIFile(path: path)
    }
    var selectedFileSupportsTimestamp: Bool {
        guard let path = selection.selectedFilePath else { return false }
        return dependencies.fileTypeProvider.isAudioFile(path: path)
    }
    var visibleTimelineComments: [Comment] {
        dependencies.commentWorkflowService.visibleTimelineComments(from: comments.selectedFileComments)
    }

    var currentUserID: String? { dependencies.authService.currentUser?.id }
    var currentHeadVersionID: String? {
        workspace.currentBranch?.headVersionID?.nonEmpty ?? project.currentVersionID.nonEmpty
    }
    var activeCommentVersionID: String? {
        workspace.selectedVersion?.id ?? currentHeadVersionID
    }
    var resolvedBranch: Branch? {
        workspace.branches.resolvingCurrent(workspace.currentBranch)
    }

    init(
        project: Project,
        dependencies: ProjectDetailViewModelDependencies
    ) {
        self.project = project
        self.dependencies = dependencies
    }

    func isAudioFile(_ url: URL) -> Bool {
        dependencies.fileTypeProvider.isAudioFile(url: url)
    }

    func iconName(forFile url: URL) -> String {
        dependencies.fileTypeProvider.iconName(for: url)
    }

    func makeAudioPlaybackService() -> AudioPlaybackServicing {
        dependencies.audioPlaybackServiceFactory.makeAudioPlaybackService(
            defaultPlaybackRate: dependencies.defaultPlaybackRate
        )
    }
}
