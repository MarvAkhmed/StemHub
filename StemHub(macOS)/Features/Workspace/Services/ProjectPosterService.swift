//
//  ProjectPosterService.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import AppKit

protocol ProjectPosterImageProviding {
    func image(from base64: String?) -> NSImage?
}

protocol ProjectPosterManaging: ProjectPosterImageProviding {
    func updatePoster(_ image: NSImage, projectID: String) async throws -> String
}

final class ProjectPosterService: ProjectPosterManaging {
    private let posterEncoder: PosterEncoding
    private let projectRepository: any ProjectPosterUpdating

    init(
        posterEncoder: PosterEncoding,
        projectRepository: any ProjectPosterUpdating
    ) {
        self.posterEncoder = posterEncoder
        self.projectRepository = projectRepository
    }

    func image(from base64: String?) -> NSImage? {
        guard let base64 else { return nil }
        return try? posterEncoder.decodeBase64JPEG(from: base64)
    }

    func updatePoster(_ image: NSImage, projectID: String) async throws -> String {
        let base64 = try posterEncoder.encodeBase64JPEG(from: image, compression: 0.7)
        try await projectRepository.updatePosterBase64(projectID: projectID, base64: base64)
        return base64
    }
}
