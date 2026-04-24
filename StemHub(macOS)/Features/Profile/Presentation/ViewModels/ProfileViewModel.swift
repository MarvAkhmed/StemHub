//
//  ProfileViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var bands: [Band] = []
    @Published private(set) var releaseCandidates: [ReleaseCandidate] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authService: any AuthenticatedUserProviding
    private let workspaceLoader: WorkspaceLoaderServiceProtocol
    private let releaseCatalog: ReleaseCatalogProviding
    private var hasLoaded = false

    init(
        authService: any AuthenticatedUserProviding,
        workspaceLoader: WorkspaceLoaderServiceProtocol,
        releaseCatalog: ReleaseCatalogProviding
    ) {
        self.authService = authService
        self.workspaceLoader = workspaceLoader
        self.releaseCatalog = releaseCatalog
    }

    var bandCountLabel: String {
        "\(bands.count) band\(bands.count == 1 ? "" : "s")"
    }

    var releaseCountLabel: String {
        "\(releaseCandidates.count) release-ready project\(releaseCandidates.count == 1 ? "" : "s")"
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
            errorMessage = "User not logged in"
            return
        }

        isLoading = true
        errorMessage = nil
        currentUser = user

        do {
            async let workspace = workspaceLoader.loadWorkspace(for: user.id)
            async let releases = releaseCatalog.fetchReleaseCandidates(for: user.id)
            let snapshot = try await workspace
            bands = snapshot.bands.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
