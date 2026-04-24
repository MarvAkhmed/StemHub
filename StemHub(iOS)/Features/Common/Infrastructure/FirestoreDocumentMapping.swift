//
//  FirestoreDocumentMapping.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import FirebaseFirestore

protocol IOSFirestoreDocumentConvertible {
    init?(documentID: String, data: [String: Any])
}

extension QueryDocumentSnapshot {
    func decoded<T: IOSFirestoreDocumentConvertible>(as type: T.Type = T.self) -> T? {
        T(documentID: documentID, data: data())
    }
}

extension Dictionary where Key == String, Value == Any {
    func string(_ key: String, default defaultValue: String = "") -> String {
        self[key] as? String ?? defaultValue
    }

    func stringArray(_ key: String) -> [String] {
        self[key] as? [String] ?? []
    }

    func int(_ key: String, default defaultValue: Int = 0) -> Int {
        if let value = self[key] as? Int {
            return value
        }

        if let value = self[key] as? NSNumber {
            return value.intValue
        }

        return defaultValue
    }

    func date(_ key: String, default defaultValue: Date = .distantPast) -> Date {
        if let value = self[key] as? Date {
            return value
        }

        if let value = self[key] as? Timestamp {
            return value.dateValue()
        }

        if let value = self[key] as? TimeInterval {
            return Date(timeIntervalSince1970: value)
        }

        if let value = self[key] as? NSNumber {
            return Date(timeIntervalSince1970: value.doubleValue)
        }

        return defaultValue
    }

    func optionalDate(_ key: String) -> Date? {
        guard self[key] != nil else {
            return nil
        }

        return date(key, default: .distantPast)
    }
}
