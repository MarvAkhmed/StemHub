//
//  WorkspaceViewModel.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import Combine

@MainActor
final class WorkspaceViewModel: ObservableObject {
    @Published private(set) var bands: [IOSBandSummary] = []
    @Published private(set) var projects: [IOSProjectSummary] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let currentUser: User

    private let authService: any AuthenticatedUserProviding
    private let repository: any IOSWorkspaceLoading
    private var hasLoaded = false

    init(
        currentUser: User,
        authService: any AuthenticatedUserProviding,
        repository: any IOSWorkspaceLoading
    ) {
        self.currentUser = currentUser
        self.authService = authService
        self.repository = repository
    }

    var displayName: String {
        if let name = currentUser.name, !name.isEmpty {
            return name
        }
        if let email = currentUser.email, !email.isEmpty {
            return email
        }
        return "Producer"
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<18:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    var bandCountLabel: String {
        "\(bands.count)"
    }

    var projectCountLabel: String {
        "\(projects.count)"
    }

    var featuredProject: IOSProjectSummary? {
        projects.first
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard authService.currentUser != nil else {
            bands = []
            projects = []
            errorMessage = "User not logged in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await repository.fetchWorkspace(for: currentUser.id)
            bands = snapshot.bands
            projects = snapshot.projects
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func bandName(for project: IOSProjectSummary) -> String {
        bands.first(where: { $0.id == project.bandID })?.name ?? "Independent"
    }

    func clearError() {
        errorMessage = nil
    }
}
