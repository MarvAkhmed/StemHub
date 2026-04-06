//
//  ProjectPersistenceStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation

protocol ProjectPersistenceStrategy {
    func getLocalPath(for projectID: String) -> String
    func setLocalPath(_ path: String, for projectID: String)
    func getLastPulledVersionID(for projectID: String) -> String?
    func setLastPulledVersionID(_ versionID: String?, for projectID: String)
    func storeBookmark(data: Data, for projectID: String)
    
    func setCurrentBranchID(_ branchID: String, for projectID: String)
    func getCurrentBranchID(for projectID: String) -> String?
}
