//
//  CommitApplicationService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

protocol CommitApplicationStrategy {
    
}

final class DefaultCommitApplicationStrategy: CommitApplicationStrategy {
    let network: ProjectNetworkStrategy
    let commitStorage: LocalCommitStorageStrategy
    let diffEngine: DiffEngineStrategy
    
    init(network: ProjectNetworkStrategy, commitStorage: LocalCommitStorageStrategy, diffEngine: DiffEngineStrategy) {
        self.network = network
        self.commitStorage = commitStorage
        self.diffEngine = diffEngine
    }
    
    
}


