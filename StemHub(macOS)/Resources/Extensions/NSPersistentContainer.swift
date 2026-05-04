//
//  NSPersistentContainer.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 04.05.2026.
//

import Foundation
import CoreData

extension NSPersistentContainer {
    func performBackgroundTaskResult<T>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            self.performBackgroundTask { context in
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}


