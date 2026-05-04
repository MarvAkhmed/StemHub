//
//  Int.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

import Foundation

extension Int {
    var isPowerOfTwo: Bool {
        self > 0 && (self & (self - 1)) == 0
    }
}
