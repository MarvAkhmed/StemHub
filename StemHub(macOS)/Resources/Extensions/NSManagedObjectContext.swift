//
//  NSManagedObjectContext.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 04.05.2026.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}
