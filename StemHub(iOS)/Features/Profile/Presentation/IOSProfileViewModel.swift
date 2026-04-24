//
//  IOSProfileViewModel.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import Combine

@MainActor
final class IOSProfileViewModel: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var bands: [IOSBandSummary] = []
    @Published private(set) var releaseCandidates: [IOSReleaseCandidate] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authService: any AuthenticatedUserProviding
    private let workspaceRepository: any IOSWorkspaceLoading
    private let releaseCatalog: any IOSReleaseCatalogProviding
    private var hasLoaded = false

    init(
        authService: any AuthenticatedUserProviding,
        workspaceRepository: any IOSWorkspaceLoading,
        releaseCatalog: any IOSReleaseCatalogProviding
    ) {
        self.authService = authService
        self.workspaceRepository = workspaceRepository
        self.releaseCatalog = releaseCatalog
    }

    var bandCountLabel: String {
        "\(bands.count) band\(bands.count == 1 ? "" : "s")"
    }

    var releaseCountLabel: String {
        "\(releaseCandidates.count) release-ready"
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard let user = authService.currentUser else {
            currentUser = nil
            bands = []
            releaseCandidates = []
            errorMessage = "User not logged in."
            return
        }

        isLoading = true
        errorMessage = nil
        currentUser = user

        do {
            async let workspaceSnapshot = workspaceRepository.fetchWorkspace(for: user.id)
            async let releases = releaseCatalog.fetchReleaseCandidates(for: user.id)
            let snapshot = try await workspaceSnapshot

            bands = snapshot.bands
            releaseCandidates = try await releases
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }
}
