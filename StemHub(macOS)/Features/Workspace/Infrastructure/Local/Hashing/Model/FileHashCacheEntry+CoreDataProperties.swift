//
//  FileHashCacheEntry+CoreDataProperties.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 04.05.2026.
//
//

public import Foundation
public import CoreData


public typealias FileHashCacheEntryCoreDataPropertiesSet = NSSet

extension FileHashCacheEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileHashCacheEntry> {
        return NSFetchRequest<FileHashCacheEntry>(entityName: "FileHashCacheEntry")
    }

    @NSManaged public var cacheKey: String?
    @NSManaged public var fileHash: String?
    @NSManaged public var algorithmVersion: String?
    @NSManaged public var lastAccessedAt: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var fileSize: Int64
    @NSManaged public var modifiedAt: Date?

}

extension FileHashCacheEntry : Identifiable {

}
