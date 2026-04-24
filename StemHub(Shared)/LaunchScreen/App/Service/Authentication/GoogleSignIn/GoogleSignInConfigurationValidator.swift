//
//  GoogleSignInConfigurationValidator.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol GoogleSignInConfigurationValidating {
    func validateConfiguration(in bundle: Bundle) throws
}

struct BundleGoogleSignInConfigurationValidator: GoogleSignInConfigurationValidating {
    private let configurationLoader: FirebaseConfigurationLoading

    init(configurationLoader: FirebaseConfigurationLoading) {
        self.configurationLoader = configurationLoader
    }

    func validateConfiguration(in bundle: Bundle) throws {
        let googleServiceInfo = try configurationLoader.googleServiceInfo(in: bundle)

        guard let reversedClientID = googleServiceInfo["REVERSED_CLIENT_ID"] as? String else {
            throw AuthError.missingGoogleConfiguration
        }

        let configuredSchemes = (bundle.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? [])
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }

        guard configuredSchemes.contains(reversedClientID) else {
            throw AuthError.missingGoogleURLScheme(reversedClientID)
        }
    }
}
