//
//  StemHubIOSAppDelegate.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import UIKit

final class StemHubIOSAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseRuntimeBootstrap.ensureConfigured()
        return true
    }
}
