//
//  DiffCalculationStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol DiffCalculationStrategy {
    func computeDiff(local: [LocalFile], remote: [RemoteFileSnapshot]) -> DiffResult
    func mapToProjectDiff(_ diff: DiffResult) -> ProjectDiff
}
