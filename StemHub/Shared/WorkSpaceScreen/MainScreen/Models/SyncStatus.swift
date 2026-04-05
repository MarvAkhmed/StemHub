//
//    var path- String .swift
//  StemHub
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation


enum SyncStatus: String, Codable {
    case uploading
    case synced
    case pending
    case conflict
}
