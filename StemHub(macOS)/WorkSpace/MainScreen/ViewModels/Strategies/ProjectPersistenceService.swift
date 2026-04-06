//
//  ProjectPersistenceService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI

struct ProjectPersistenceService: ProjectPersistenceStrategy {
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func getLocalPath(for projectID: String) -> String {
        defaults.string(forKey: "project_\(projectID)_path") ?? ""
    }
    
    func setLocalPath(_ path: String, for projectID: String) {
        defaults.set(path, forKey: "project_\(projectID)_path")
    }
    
    func getLastPulledVersionID(for projectID: String) -> String? {
        defaults.string(forKey: "project_\(projectID)_lastPulled")
    }
    
    func setLastPulledVersionID(_ versionID: String?, for projectID: String) {
        defaults.set(versionID, forKey: "project_\(projectID)_lastPulled")
    }
    
    
    func storeBookmark(data: Data, for projectID: String) {
        defaults.set(data, forKey: "project_\(projectID)_bookmark")
    }
    
    
    func setCurrentBranchID(_ branchID: String, for projectID: String) {
        defaults.set(branchID, forKey: "project_\(projectID)_branchID")
    }

    func getCurrentBranchID(for projectID: String) -> String? {
        defaults.string(forKey: "project_\(projectID)_branchID")
    }
}
