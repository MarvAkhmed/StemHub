//
//  PlatformFirebaseConfiguration.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import Foundation

enum PlatformFirebaseConfiguration {
    static let plistExtension = "plist"

    static var resourceName: String {
        #if os(iOS)
        return "GoogleService-Info-iOS"
        #elseif os(macOS)
        return "GoogleService-Info-macOS"
        #else
        return "GoogleService-Info"
        #endif
    }

    static var fileName: String {
        "\(resourceName).\(plistExtension)"
    }
}
