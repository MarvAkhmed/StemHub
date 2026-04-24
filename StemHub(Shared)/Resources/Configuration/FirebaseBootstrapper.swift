//
//  FirebaseBootstrapper.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import FirebaseCore
import Foundation
import GoogleSignIn

protocol FirebaseBootstrapping {
    func configureIfNeeded(in bundle: Bundle) throws
}

struct FirebaseBootstrapper: FirebaseBootstrapping {
    private let configurationLoader: FirebaseConfigurationLoading

    init(configurationLoader: FirebaseConfigurationLoading) {
        self.configurationLoader = configurationLoader
    }

    func configureIfNeeded(in bundle: Bundle) throws {
        let options = try configurationLoader.firebaseOptions(in: bundle)

        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }

        guard let clientID = FirebaseApp.app()?.options.clientID ?? options.clientID,
              clientID.isEmpty == false else {
            throw AuthError.missingGoogleConfiguration
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
}
