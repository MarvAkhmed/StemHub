//
//  FirebaseConfigurationLoading.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import FirebaseCore
import Foundation

protocol FirebaseConfigurationLoading {
    func googleServiceInfo(in bundle: Bundle) throws -> [String: Any]
    func firebaseOptions(in bundle: Bundle) throws -> FirebaseOptions
}

struct BundleFirebaseConfigurationLoader: FirebaseConfigurationLoading {
    func googleServiceInfo(in bundle: Bundle) throws -> [String: Any] {
        let configurationURL = try configurationURL(in: bundle)

        guard let googleServiceInfo = NSDictionary(contentsOf: configurationURL) as? [String: Any] else {
            throw AuthError.missingGoogleConfiguration
        }

        try validateBundleIdentifier(googleServiceInfo: googleServiceInfo, bundle: bundle)
        return googleServiceInfo
    }

    func firebaseOptions(in bundle: Bundle) throws -> FirebaseOptions {
        let configurationURL = try configurationURL(in: bundle)
        _ = try googleServiceInfo(in: bundle)

        guard let options = FirebaseOptions(contentsOfFile: configurationURL.path) else {
            throw AuthError.missingGoogleConfiguration
        }

        return options
    }
}

private extension BundleFirebaseConfigurationLoader {
    func configurationURL(in bundle: Bundle) throws -> URL {
        guard let configurationURL = bundle.url(
            forResource: PlatformFirebaseConfiguration.resourceName,
            withExtension: PlatformFirebaseConfiguration.plistExtension
        ) else {
            throw AuthError.missingGoogleConfiguration
        }

        return configurationURL
    }

    func validateBundleIdentifier(
        googleServiceInfo: [String: Any],
        bundle: Bundle
    ) throws {
        guard
            let configuredBundleIdentifier = googleServiceInfo["BUNDLE_ID"] as? String,
            let runtimeBundleIdentifier = bundle.bundleIdentifier,
            configuredBundleIdentifier != runtimeBundleIdentifier
        else {
            return
        }

        throw AuthError.firebaseBundleIdentifierMismatch(
            expected: runtimeBundleIdentifier,
            configured: configuredBundleIdentifier
        )
    }
}
