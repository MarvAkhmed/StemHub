//
//  UserRepository.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol RemoteUserRepository:
    UserDirectoryReading,
    UserEmailLookup {}

protocol UserRepository: RemoteUserRepository {}
