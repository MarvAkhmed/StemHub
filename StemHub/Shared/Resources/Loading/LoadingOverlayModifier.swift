//
//  LoadingOverlayModifier.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
            
            if isLoading {
                LoadingView(message: message)
            }
        }
    }
}

