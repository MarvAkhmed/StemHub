//
//  ProjectDetailViewModel+Activity.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

extension ProjectDetailViewModel {
    func performActivity(
        _ activity: ProjectDetailActivityState,
        operation: () async throws -> Void
    ) async {
        guard ui.activityState == .idle else { return }

        ui.activityState = activity
        ui.errorMessage = nil

        do {
            try await operation()
        } catch {
            if case ProjectDetailError.folderNotWritable = error {
                ui.showRelocationAlert = true
            }
            if case ProjectDetailError.missingProjectFolder = error {
                ui.showRelocationAlert = true
            }

            ui.errorMessage = error.localizedDescription
        }

        ui.activityState = .idle
    }

    func clearError() {
        ui.errorMessage = nil
    }
}
