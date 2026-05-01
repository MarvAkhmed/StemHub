//
//  Array.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

extension Array where Element == User {
    func displayName(for userID: String) -> String {
        first(where: { $0.id == userID })?.name
        ?? first(where: { $0.id == userID })?.email
        ?? String(userID.prefix(8))
    }
}

extension Array where Element == ProjectVersion {
    func versionTitle(defaultTitle: String = "Working Copy") -> String {
        guard let version = first else { return defaultTitle }
        return "Version \(version.versionNumber)"
    }

    func versionNumberText(defaultValue: Int = 0) -> String {
        String(first?.versionNumber ?? defaultValue)
    }

    func version(matching id: String?) -> ProjectVersion? {
        guard let id else { return nil }
        return first { $0.id == id }
    }
}

extension Array where Element == Branch {
    var mainBranch: Branch? {
        first(where: { $0.name == "main" })
    }
    
    func resolvingCurrent(_ currentBranch: Branch?) -> Branch? {
         currentBranch ?? mainBranch
     }
    
    func updating(_ branch: Branch) -> [Branch] {
        map { $0.id == branch.id ? branch : $0 }
    }
}
