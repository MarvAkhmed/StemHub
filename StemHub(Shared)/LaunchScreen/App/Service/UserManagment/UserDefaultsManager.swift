//
//  UserDefaultsManager.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation

protocol UserDefaultsManaging {
    func saveUser(_ user: User?)
    func loadUser() -> User?
    func clearUser()
}

final class UserDefaultsManager: UserDefaultsManaging {
    
    static let shared = UserDefaultsManager()
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    
    private init() {}
    
    func saveUser(_ user: User?) {
        guard let user = user,
              let encoded = try? JSONEncoder().encode(user) else {
            userDefaults.removeObject(forKey: userKey)
            return
        }
        userDefaults.set(encoded, forKey: userKey)
    }
    
    func loadUser() -> User? {
        guard let data = userDefaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    func clearUser() {
        userDefaults.removeObject(forKey: userKey)
    }
}
