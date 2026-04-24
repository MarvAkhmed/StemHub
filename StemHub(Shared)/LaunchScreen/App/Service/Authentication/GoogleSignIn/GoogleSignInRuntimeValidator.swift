//
//  GoogleSignInRuntimeValidator.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

protocol GoogleSignInRuntimeValidating {
    func validate(in bundle: Bundle) throws
}

struct GoogleSignInRuntimeValidator: GoogleSignInRuntimeValidating {
    private let configurationValidator: GoogleSignInConfigurationValidating
    private let entitlementInspector: AppEntitlementInspecting

    init(
        configurationValidator: GoogleSignInConfigurationValidating,
        entitlementInspector: AppEntitlementInspecting
    ) {
        self.configurationValidator = configurationValidator
        self.entitlementInspector = entitlementInspector
    }

    func validate(in bundle: Bundle) throws {
        try configurationValidator.validateConfiguration(in: bundle)

        #if os(macOS)
        try validateKeychainSharing()
        #endif
    }

    #if os(macOS)
    private func validateKeychainSharing() throws {
        let keychainAccessGroups = entitlementInspector.stringArrayValue(for: "keychain-access-groups") ?? []

        guard keychainAccessGroups.isEmpty == false else {
            throw AuthError.missingKeychainSharing
        }
    }
    #endif
}

