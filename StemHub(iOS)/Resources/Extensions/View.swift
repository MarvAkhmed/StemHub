//
//  View.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation
import SwiftUI

extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }

    func iosStudioScreenBackground() -> some View {
        background(IOSStudioBackground())
    }
}
