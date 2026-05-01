//
//  QueryDocumentSnapshot.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 25.04.2026.
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
