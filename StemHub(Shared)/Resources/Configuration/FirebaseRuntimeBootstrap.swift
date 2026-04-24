//
//  FirebaseRuntimeBootstrap.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import FirebaseCore
import Foundation

enum FirebaseRuntimeBootstrap {
    private static let lock = NSLock()
    private static let configurationLoader: FirebaseConfigurationLoading = BundleFirebaseConfigurationLoader()
    private static let bootstrapper: FirebaseBootstrapping = FirebaseBootstrapper(
        configurationLoader: configurationLoader
    )

    static func ensureConfigured(bundle: Bundle = .main) {
        lock.lock()
        defer { lock.unlock() }

        do {
            try bootstrapper.configureIfNeeded(in: bundle)
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }
}
