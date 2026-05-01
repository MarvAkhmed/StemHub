//
//  StemHubMacOSAppDelegate.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import AppKit

final class StemHubMacOSAppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseRuntimeBootstrap.ensureConfigured()
    }
}
