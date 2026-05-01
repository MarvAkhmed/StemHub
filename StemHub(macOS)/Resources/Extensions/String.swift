//
//  String.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var nonEmpty: String? {
        let trimmed = trimmed
        return trimmed.isEmpty ? nil : trimmed
    }
}
