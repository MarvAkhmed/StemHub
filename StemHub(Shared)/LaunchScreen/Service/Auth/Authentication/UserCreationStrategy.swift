//
//  UserFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import FirebaseAuth

protocol UserCreationStrategy {
    func create(from authResult: AuthDataResult, email: String, name: String?) -> User
}
