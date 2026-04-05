//
//  UserDefaultsManager.swift
//  StemHub
//
//  Created by Marwa Awad on 31.03.2026.
//

import Foundation
#if  os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

final class UserDefaultsManager {
    
    private static let lastUserKey = "lastLoggedInUser"
    
    static func saveUser(_ user: User?) {
        guard let user = user else {
            clearUser()
            return
        }
        
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: lastUserKey)
        } catch {
            print("⚠️ Failed to encode user for UserDefaults: \(error)")
        }
    }
    
    static func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: lastUserKey) else {
            return nil
        }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            return user
        } catch {
            return nil
        }
    }
    
    static func clearUser() {
        UserDefaults.standard.removeObject(forKey: lastUserKey)
    }
}
