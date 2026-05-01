//
//  ProjectDetailViewModelDependencies.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

struct ProjectDetailViewModelDependencies {
    let authService: any AuthenticatedUserProviding
    let collaborationService: ProjectCollaborationServiceProtocol
    let projectPosterService: ProjectPosterManaging
    let detailWorkspaceService: ProjectDetailWorkspaceLoading
    let versionWorkflowService: ProjectVersionWorkflowing
    let commentWorkflowService: ProjectCommentWorkflowing
    let timestampedCommentService: TimestampedCommentServing
    let fileWorkflowService: ProjectFileWorkflowing
    let commitWorkflowService: ProjectCommitWorkflowing
    let branchWorkflowService: ProjectDetailBranchWorkflowing
    let fileTypeProvider: ProjectFileTypeProviding
    let midiSessionResolver: ProjectMIDISessionResolving
    let folderPicker: FolderPicking
    let audioPicker: AudioFilePicking
    let imagePicker: ImagePicking
    let audioPlaybackPreparer: AudioPlaybackPreparing
    let audioPlaybackServiceFactory: AudioPlaybackServiceMaking
    let defaultPlaybackRate: Double
}
