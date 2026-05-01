//
//  Optional.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 29.04.2026.
//

import Foundation

extension Optional where Wrapped == String {
    var fileDisplayName: String {
        guard let self else { return "No File Selected" }
        return (self as NSString).lastPathComponent
    }
    
    var orEmpty: String {
        self ?? ""
    }
}
