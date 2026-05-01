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
    private static var didConfigure = false

    private static let configurationLoader: FirebaseConfigurationLoading = BundleFirebaseConfigurationLoader()

    private static let bootstrapper: FirebaseBootstrapping = FirebaseBootstrapper(
        configurationLoader: configurationLoader
    )

    static func ensureConfigured(bundle: Bundle = .main) {
        lock.lock()
        defer { lock.unlock() }

        guard didConfigure == false else { return }

        do {
            try bootstrapper.configureIfNeeded(in: bundle)
            didConfigure = true
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }
}

