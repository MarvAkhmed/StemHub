//
//  SHA256.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

import Foundation
import CryptoKit

extension SHA256.Digest {
    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
