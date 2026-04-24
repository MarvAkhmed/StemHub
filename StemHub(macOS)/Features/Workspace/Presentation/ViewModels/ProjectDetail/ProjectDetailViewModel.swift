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
    @Published private(set) var project: Project
    @Published private(set) var band: Band?
    @Published private(set) var branches: [Branch] = []
    @Published private(set) var currentBranch: Branch?
    @Published private(set) var versionHistory: [ProjectVersion] = []
    @Published private(set) var selectedVersion: ProjectVersion?
    @Published private(set) var versionDiff: ProjectDiff?
    @Published private(set) var fileTree: [FileTreeNode] = []
    @Published private(set) var members: [User] = []
    @Published private(set) var selectedFileComments: [Comment] = []
    @Published private(set) var versionComments: [Comment] = []
    @Published private(set) var pendingInvitations: [BandInvitation] = []
    @Published private(set) var localCommits: [LocalCommit] = []
    @Published private(set) var selectedFileURL: URL?
    @Published private(set) var selectedFilePath: String?
    @Published private(set) var activityState: ProjectDetailActivityState = .idle
    @Published var midiEditorSession: ProjectMIDISession?
    @Published var selectedCommentTimestamp: Double?
    @Published var newBranchName = ""
    @Published var inviteMemberEmail = ""
    @Published var newCommentText = ""
    @Published var errorMessage: String?
    @Published var showRelocationAlert = false

    private let authService: any AuthenticatedUserProviding
    private let syncService: ProjectSyncService
    private let versionService: ProjectVersionService
    private let versionApprovalService: ProjectVersionApprovalServiceProtocol
    private let branchService: ProjectBranchServiceProtocol
    private let collaborationService: ProjectCollaborationServiceProtocol
    private let commentService: ProjectCommentServiceProtocol
    private let localWorkspace: ProjectLocalWorkspaceService
    private let stateStore: ProjectStateStore
    private let projectRepository: any ProjectPosterUpdating & ProjectWorkspaceStateUpdating
    private let midiSessionResolver: ProjectMIDISessionResolving
    private let folderPicker: FolderPicking
    private let audioPicker: AudioFilePicking
    private let imagePicker: ImagePicking
    private let posterEncoder: PosterEncoding
    let audioPlaybackPreparer: AudioPlaybackPreparing
    let defaultPlaybackRate: Double

    private var hasLoadedInitialState = false

    var isLoading: Bool { activityState.isLoading }
    var projectName: String { project.name }
    var currentBranchName: String { currentBranch?.name ?? "main" }
    var currentVersionID: String { currentHeadVersionID ?? "" }
    var currentVersionNumber: String { String(versionHistory.first?.versionNumber ?? 0) }
    var projectPosterImage: NSImage? {
        guard
            let base64 = project.posterBase64,
            let data = Data(base64Encoded: base64)
        else {
            return nil
        }

        return NSImage(data: data)
    }
    var canCommit: Bool { currentBranch != nil && currentUserID != nil }
    var canApproveSelectedVersion: Bool {
        isCurrentUserAdmin &&
        selectedVersion?.approvalState == .pendingReview
    }
    var canCreateBranch: Bool { !newBranchName.trimmed.isEmpty && currentUserID != nil }
    var canInviteMember: Bool { isCurrentUserAdmin && !inviteMemberEmail.trimmed.isEmpty }
    var canAddComment: Bool {
        !newCommentText.trimmed.isEmpty &&
        selectedFilePath != nil &&
        activeCommentVersionID != nil &&
        currentBranch != nil
    }
    var pendingCommitCount: Int { localCommits.count }
    var isCurrentUserAdmin: Bool {
        guard let currentUserID, let band else { return false }
        return band.isAdmin(userID: currentUserID)
    }
    var projectSubtitle: String {
        band?.name ?? "Collaborative project workspace"
    }
    var currentVersionTitle: String {
        if let version = versionHistory.first {
            return "Version \(version.versionNumber)"
        }

        return "Working Copy"
    }
    var workspaceTitle: String {
        if let selectedVersion {
            return "Reviewing Version \(selectedVersion.versionNumber)"
        }

        return "Working Copy"
    }
    var workspaceSubtitle: String {
        if let selectedVersion {
            return selectedVersion.createdAt.formatted(
                .dateTime.month(.abbreviated).day().hour().minute()
            )
        }

        return "Live branch workspace with local edits and pending commits."
    }
    var selectedFileDisplayName: String {
        if let selectedFilePath {
            return (selectedFilePath as NSString).lastPathComponent
        }

        return "No File Selected"
    }
    var selectedFileIsMIDI: Bool {
        guard let selectedFilePath else { return false }
        return Self.isMIDIFile(path: selectedFilePath)
    }
    var selectedCommentTimestampLabel: String {
        guard let selectedCommentTimestamp else { return "No timestamp selected" }
        return Self.formatTimestamp(selectedCommentTimestamp)
    }
    var selectedFileSupportsTimestamp: Bool {
        guard let selectedFilePath else { return false }
        return Self.isAudioFile(path: selectedFilePath)
    }
    var visibleTimelineComments: [Comment] {
        selectedFileComments.filter { $0.timestamp != nil && $0.isHiddenFromTimeline == false }
    }
    var selectedVersionStatusTitle: String {
        selectedVersion?.approvalState.title ?? "Working Copy"
    }

    private var currentUserID: String? { authService.currentUser?.id }
    private var currentHeadVersionID: String? {
        currentBranch?.headVersionID?.nonEmpty ?? project.currentVersionID.nonEmpty
    }
    private var activeCommentVersionID: String? {
        selectedVersion?.id ?? currentHeadVersionID
    }

    init(
        project: Project,
        authService: any AuthenticatedUserProviding,
        syncService: ProjectSyncService,
        versionService: ProjectVersionService,
        versionApprovalService: ProjectVersionApprovalServiceProtocol,
        branchService: ProjectBranchServiceProtocol,
        collaborationService: ProjectCollaborationServiceProtocol,
        commentService: ProjectCommentServiceProtocol,
        localCommitStore: LocalCommitStore,
        folderService: any ProjectFolderService,
        stateStore: ProjectStateStore,
        projectRepository: any ProjectPosterUpdating & ProjectWorkspaceStateUpdating,
        midiSessionResolver: ProjectMIDISessionResolving,
        folderPicker: FolderPicking,
        audioPicker: AudioFilePicking,
        imagePicker: ImagePicking,
        posterEncoder: PosterEncoding,
        audioPlaybackPreparer: AudioPlaybackPreparing,
        defaultPlaybackRate: Double
    ) {
        self.project = project
        self.authService = authService
        self.syncService = syncService
        self.versionService = versionService
        self.versionApprovalService = versionApprovalService
        self.branchService = branchService
        self.collaborationService = collaborationService
        self.commentService = commentService
        self.localWorkspace = ProjectLocalWorkspaceService(
            folderService: folderService,
            localCommitStore: localCommitStore
        )
        self.stateStore = stateStore
        self.projectRepository = projectRepository
        self.midiSessionResolver = midiSessionResolver
        self.folderPicker = folderPicker
        self.audioPicker = audioPicker
        self.imagePicker = imagePicker
        self.posterEncoder = posterEncoder
        self.audioPlaybackPreparer = audioPlaybackPreparer
        self.defaultPlaybackRate = defaultPlaybackRate
    }

    func loadInitialStateIfNeeded() async {
        guard !hasLoadedInitialState else { return }

        await performActivity(.loading) {
            try await refreshWorkspaceState()
            hasLoadedInitialState = true
        }
    }

    func loadVersionHistory() async {
        await performActivity(.loading) {
            try await refreshWorkspaceState(
                preserveSelectedVersionID: selectedVersion?.id
            )
        }
    }

    func loadFiles() async {
        await performActivity(.loading) {
            selectedVersion = nil
            versionDiff = nil
            fileTree = await localWorkspace.loadFileTree(projectID: project.id)
            localCommits = await localWorkspace.loadLocalCommits(projectID: project.id)
            try await restoreSelectedFileSelection()
            try await refreshComments()
        }
    }

    func loadVersionDetails(versionID: String) async {
        await performActivity(.loading) {
            let fetchedVersion = try await versionService.fetchVersion(versionID: versionID)

            guard let version = versionHistory.first(where: { $0.id == versionID }) ?? fetchedVersion else {
                throw ProjectDetailError.missingVersionContext
            }

            selectedVersion = version
            versionDiff = version.diff
            try await refreshComments()
        }
    }

    func selectFile(_ url: URL?) async {
        selectedCommentTimestamp = nil
        selectedFileURL = url
        selectedFilePath = await resolveRelativePath(for: url)

        do {
            try await refreshComments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchBranch(_ branchID: String) async {
        await performActivity(.switchingBranch) {
            let branchState = try await branchService.loadBranchWorkspace(
                projectID: project.id,
                selectedBranchID: branchID,
                fallbackBranchID: currentBranch?.id ?? project.currentBranchID
            )

            stateStore.setCurrentBranchID(branchState.selectedBranch.id, for: project.id)
            applyBranchWorkspace(branchState, preserveSelectedVersionID: nil)

            if await localWorkspace.isProjectFolderWritable(projectID: project.id),
               branchState.selectedBranch.headVersionID != nil {
                _ = try await syncService.pull(
                    projectID: project.id,
                    branchID: branchState.selectedBranch.id
                )
            } else if await localWorkspace.resolveFolderURL(projectID: project.id) != nil {
                showRelocationAlert = true
            }

            try await refreshWorkspaceState()
            try await persistWorkspaceState()
        }
    }

    func createBranch() async {
        guard let currentUserID else {
            errorMessage = ProjectDetailError.userNotSignedIn.localizedDescription
            return
        }

        let branchName = newBranchName.trimmed

        await performActivity(.creatingBranch) {
            let branch = try await branchService.createBranch(
                projectID: project.id,
                name: branchName,
                sourceVersionID: currentHeadVersionID,
                createdBy: currentUserID
            )

            newBranchName = ""
            stateStore.setCurrentBranchID(branch.id, for: project.id)
            try await refreshWorkspaceState()
            try await persistWorkspaceState()
        }
    }

    func sendBandInvite() async {
        guard let currentUserID else {
            errorMessage = ProjectDetailError.userNotSignedIn.localizedDescription
            return
        }

        let email = inviteMemberEmail.trimmed

        await performActivity(.invitingMember) {
            pendingInvitations = try await collaborationService.inviteMember(
                email: email,
                bandID: project.bandID,
                bandName: band?.name ?? projectSubtitle,
                requestedBy: currentUserID
            )
            inviteMemberEmail = ""
        }
    }

    func addComment() async {
        guard let currentUserID else {
            errorMessage = ProjectDetailError.userNotSignedIn.localizedDescription
            return
        }

        guard let currentBranch else {
            errorMessage = ProjectDetailError.missingBranch.localizedDescription
            return
        }

        guard let selectedFilePath else {
            errorMessage = ProjectDetailError.missingSelectedFile.localizedDescription
            return
        }

        guard let versionID = activeCommentVersionID else {
            errorMessage = ProjectDetailError.missingVersionContext.localizedDescription
            return
        }

        let commentText = newCommentText.trimmed
        let timestamp = selectedFileSupportsTimestamp ? selectedCommentTimestamp : nil

        await performActivity(.savingComment) {
            _ = try await commentService.addComment(
                projectID: project.id,
                branchID: currentBranch.id,
                versionID: versionID,
                filePath: selectedFilePath,
                text: commentText,
                timestamp: timestamp,
                userID: currentUserID
            )

            newCommentText = ""
            try await refreshComments()
        }
    }

    func setCommentReviewState(
        _ state: CommentReviewState,
        for comment: Comment
    ) async {
        await performActivity(.savingComment) {
            try await commentService.updateCommentReview(
                commentID: comment.id,
                reviewState: state,
                isHiddenFromTimeline: state == .accepted
            )
            try await refreshComments()
        }
    }

    func focus(on comment: Comment) async {
        selectedFilePath = comment.filePath
        selectedCommentTimestamp = comment.timestamp
        try? await restoreSelectedFileSelection()

        do {
            try await refreshSelectedFileComments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func authorName(for userID: String) -> String {
        members.first(where: { $0.id == userID })?.name
        ?? members.first(where: { $0.id == userID })?.email
        ?? String(userID.prefix(8))
    }

    func pullLatest() async {
        await performActivity(.pulling) {
            let branch = try requireCurrentBranch()
            try await ensureWritableProjectFolder()

            _ = try await syncService.pull(projectID: project.id, branchID: branch.id)
            try await refreshWorkspaceState()
            try await persistWorkspaceState()
        }
    }

    func prepareCommitDraft(message: String, stagedFiles: [LocalFile]?) async -> Commit? {
        do {
            return try await createCommitDraft(
                message: message,
                stagedFiles: stagedFiles
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func stageCommitDraft(_ draft: Commit) async {
        await performActivity(.committing) {
            try await cacheCommitDraft(draft)
        }
    }

    func pushAllCommits() async {
        await performActivity(.pushing) {
            let branch = try requireCurrentBranch()
            var pendingCommits = await localWorkspace.loadLocalCommits(projectID: project.id)
            guard !pendingCommits.isEmpty else { return }

            for localCommit in pendingCommits.sorted(by: { $0.createdAt < $1.createdAt }) {
                let pushedVersion = try await pushCommit(localCommit, branchID: branch.id)
                pendingCommits.removeAll { $0.id == localCommit.id }
                await localWorkspace.saveLocalCommits(pendingCommits, projectID: project.id)
                localCommits = pendingCommits
                updateCurrentBranchVersion(to: pushedVersion.id)
            }

            try await refreshWorkspaceState()
            try await persistWorkspaceState()
        }
    }

    func importAudioFiles() async {
        let selectedFiles = await audioPicker.selectAudioFiles(title: "Select Audio Files")
        guard !selectedFiles.isEmpty else { return }

        await performActivity(.importingFiles) {
            try await ensureWritableProjectFolder()
            let importedURLs = try await localWorkspace.importAudioFiles(selectedFiles, projectID: project.id)
            fileTree = await localWorkspace.loadFileTree(projectID: project.id)

            if let firstImportedURL = importedURLs.first {
                await selectFile(firstImportedURL)
            }
        }
    }

    func selectAndUpdatePoster() async {
        guard let image = await imagePicker.selectImage() else { return }

        await performActivity(.savingPoster) {
            let base64 = try posterEncoder.encodeBase64JPEG(from: image, compression: 0.7)
            try await projectRepository.updatePosterBase64(projectID: project.id, base64: base64)
            project.posterBase64 = base64
        }
    }

    func fixFolderPath() async {
        let selectedFolder = await folderPicker.selectFolder(
            title: "Select Project Folder",
            message: "Choose the local folder for this project."
        )
        guard let selectedFolder else { return }

        await performActivity(.fixingFolder) {
            try await localWorkspace.updateFolderReference(projectID: project.id, folderURL: selectedFolder)
            showRelocationAlert = false
            try await refreshWorkspaceState(
                preserveSelectedVersionID: selectedVersion?.id
            )
        }
    }

    func relocateProjectFolder() async {
        let destinationFolder = await folderPicker.selectFolder(
            title: "Choose New Parent Folder",
            message: "StemHub will move this project folder there."
        )
        guard let destinationFolder else { return }

        await performActivity(.relocatingFolder) {
            _ = try await localWorkspace.relocateProjectFolder(
                projectID: project.id,
                destinationParentURL: destinationFolder
            )
            showRelocationAlert = false
            try await refreshWorkspaceState(
                preserveSelectedVersionID: selectedVersion?.id
            )
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func openMIDIEditor() async {
        await performActivity(.openingMIDIEditor) {
            let session = try await midiSessionResolver.resolveSession(
                project: project,
                selectedFileURL: selectedFileURL,
                currentBranchName: currentBranchName,
                currentVersionTitle: currentVersionTitle
            )

            selectedFilePath = session.relativePath
            if session.fileExists {
                selectedFileURL = session.fileURL
            }

            midiEditorSession = session
        }
    }

    func approveSelectedVersion() async {
        guard
            let currentUserID,
            let selectedVersion,
            isCurrentUserAdmin
        else {
            errorMessage = "Only the band admin can approve versions."
            return
        }

        await performActivity(.approvingVersion) {
            try await versionApprovalService.approveVersion(
                versionID: selectedVersion.id,
                approvedBy: currentUserID
            )
            try await refreshWorkspaceState(
                preserveSelectedVersionID: selectedVersion.id
            )
        }
    }
}

private extension ProjectDetailViewModel {
    func performActivity(
        _ activity: ProjectDetailActivityState,
        operation: () async throws -> Void
    ) async {
        guard activityState == .idle else { return }

        activityState = activity
        errorMessage = nil

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }

        activityState = .idle
    }

    func refreshWorkspaceState(
        preserveSelectedVersionID: String? = nil
    ) async throws {
        let preferredBranchID = stateStore.getCurrentBranchID(for: project.id)?.nonEmpty
            ?? currentBranch?.id
            ?? project.currentBranchID

        async let branchWorkspace = branchService.loadBranchWorkspace(
            projectID: project.id,
            selectedBranchID: preferredBranchID,
            fallbackBranchID: project.currentBranchID
        )
        async let fetchedBand = collaborationService.fetchBand(bandID: project.bandID)
        async let fetchedMembers = collaborationService.fetchMembers(bandID: project.bandID)
        async let fetchedPendingInvitations = collaborationService.fetchPendingInvitations(bandID: project.bandID)
        async let fetchedCommits = localWorkspace.loadLocalCommits(projectID: project.id)
        async let fetchedTree = localWorkspace.loadFileTree(projectID: project.id)

        applyBranchWorkspace(
            try await branchWorkspace,
            preserveSelectedVersionID: preserveSelectedVersionID
        )
        band = try await fetchedBand
        members = try await fetchedMembers
        pendingInvitations = try await fetchedPendingInvitations
        localCommits = await fetchedCommits
        fileTree = await fetchedTree

        try await restoreSelectedFileSelection()
        try await refreshComments()
    }

    func createCommitDraft(
        message: String,
        stagedFiles: [LocalFile]?
    ) async throws -> Commit {
        guard let currentUserID else {
            throw ProjectDetailError.userNotSignedIn
        }

        let branch = try requireCurrentBranch()
        try await ensureWritableProjectFolder()
        try await syncService.ensureRemoteHeadIsCurrent(projectID: project.id, branchID: branch.id)

        return try await syncService.createCommit(
            projectID: project.id,
            branchID: branch.id,
            stagedFiles: stagedFiles ?? [],
            userID: currentUserID,
            message: message.trimmed
        )
    }

    func cacheCommitDraft(_ commit: Commit) async throws {
        let branch = try requireCurrentBranch()
        let localCommit = try await localWorkspace.cacheCommit(commit, projectID: project.id)
        var updatedCommits = await localWorkspace.loadLocalCommits(projectID: project.id)
        updatedCommits.append(localCommit)
        await localWorkspace.saveLocalCommits(updatedCommits, projectID: project.id)
        localCommits = updatedCommits.sorted { $0.createdAt < $1.createdAt }

        var syncState = stateStore.syncState(for: project.id)
        syncState.lastCommittedID = commit.id
        syncState.currentBranchID = branch.id
        stateStore.saveSyncState(syncState)
    }

    func applyBranchWorkspace(
        _ branchWorkspace: BranchWorkspaceState,
        preserveSelectedVersionID: String? = nil
    ) {
        branches = branchWorkspace.branches
        currentBranch = branchWorkspace.selectedBranch
        versionHistory = branchWorkspace.versionHistory
        project.currentBranchID = branchWorkspace.selectedBranch.id
        project.currentVersionID = branchWorkspace.headVersionID ?? ""

        if let preserveSelectedVersionID {
            selectedVersion = versionHistory.first { $0.id == preserveSelectedVersionID }
            versionDiff = selectedVersion?.diff
        } else {
            selectedVersion = nil
            versionDiff = nil
        }
    }

    func refreshComments() async throws {
        guard let versionID = activeCommentVersionID else {
            selectedFileComments = []
            versionComments = []
            return
        }

        versionComments = try await commentService.fetchComments(versionID: versionID)
        try await refreshSelectedFileComments()
    }

    func refreshSelectedFileComments() async throws {
        guard
            let currentBranch,
            let versionID = activeCommentVersionID,
            let selectedFilePath
        else {
            selectedFileComments = []
            selectedCommentTimestamp = nil
            return
        }

        selectedFileComments = try await commentService.fetchComments(
            projectID: project.id,
            branchID: currentBranch.id,
            versionID: versionID,
            filePath: selectedFilePath
        )
    }

    func resolveRelativePath(for url: URL?) async -> String? {
        guard let url else { return nil }
        return await localWorkspace.relativePath(for: url, projectID: project.id)
    }

    func restoreSelectedFileSelection() async throws {
        guard let selectedFilePath else {
            selectedFileURL = nil
            return
        }

        guard let folderURL = await localWorkspace.resolveFolderURL(projectID: project.id) else {
            selectedFileURL = nil
            selectedFileComments = []
            return
        }

        let resolvedURL = folderURL.appendingPathComponent(selectedFilePath)
        if FileManager.default.fileExists(atPath: resolvedURL.path) {
            selectedFileURL = resolvedURL
        } else {
            self.selectedFilePath = nil
            selectedFileURL = nil
            selectedFileComments = []
        }
    }

    func requireCurrentBranch() throws -> Branch {
        guard let currentBranch else {
            throw ProjectDetailError.missingBranch
        }

        return currentBranch
    }

    func ensureWritableProjectFolder() async throws {
        guard await localWorkspace.resolveFolderURL(projectID: project.id) != nil else {
            throw ProjectDetailError.missingProjectFolder
        }

        guard await localWorkspace.isProjectFolderWritable(projectID: project.id) else {
            showRelocationAlert = true
            throw ProjectDetailError.folderNotWritable
        }
    }

    func persistWorkspaceState() async throws {
        guard let currentBranch else { return }

        try await projectRepository.updateWorkspaceState(
            projectID: project.id,
            currentBranchID: currentBranch.id,
            currentVersionID: currentBranch.headVersionID
        )
    }

    func pushCommit(_ localCommit: LocalCommit, branchID: String) async throws -> ProjectVersion {
        do {
            return try await syncService.pushCommit(localCommit, branchID: branchID)
        }
        catch SyncError.outdatedCommit {
            let latestBranchState = try await branchService.loadBranchWorkspace(
                projectID: project.id,
                selectedBranchID: branchID,
                fallbackBranchID: branchID
            )
            
            guard let headVersionID = latestBranchState.headVersionID else {
                throw ProjectBranchError.missingSourceVersion
            }
            
            let rebasedCommit = try await syncService.rebaseCommit(localCommit, onto: headVersionID)
            return try await syncService.pushCommit(rebasedCommit, branchID: branchID)
        }
    }

    func updateCurrentBranchVersion(to versionID: String) {
        guard var currentBranch else { return }
        currentBranch.headVersionID = versionID
        self.currentBranch = currentBranch
        project.currentVersionID = versionID
    }

    static func isAudioFile(path: String) -> Bool {
        let fileExtension = (path as NSString).pathExtension.lowercased()
        return ["mp3", "wav", "aif", "aiff", "m4a", "aac", "caf"].contains(fileExtension)
    }

    static func isMIDIFile(path: String) -> Bool {
        let fileExtension = (path as NSString).pathExtension.lowercased()
        return ["mid", "midi"].contains(fileExtension)
    }

    static func formatTimestamp(_ time: Double) -> String {
        let totalSeconds = max(Int(time.rounded(.down)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nonEmpty: String? {
        let trimmed = trimmed
        return trimmed.isEmpty ? nil : trimmed
    }
}
