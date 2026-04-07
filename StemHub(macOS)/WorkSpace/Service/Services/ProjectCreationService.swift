//
//  ProjectCreationService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation


protocol ProjectCreationServiceProtocol {
    
}

final class ProjectCreationService: ProjectCreationServiceProtocol {
    private let network: ProjectNetworkStrategy
    private let persistence: ProjectPersistenceStrategy
    private let bookmark: BookmarkStrategy
    private let posterEncoder: PosterEncoderStrategy
    
    init(network: ProjectNetworkStrategy,
         persistence: ProjectPersistenceStrategy,
         bookmark: BookmarkStrategy,
         posterEncoder: PosterEncoderStrategy) {
        self.network = network
        self.persistence = persistence
        self.bookmark = bookmark
        self.posterEncoder = posterEncoder
    }
    
}
