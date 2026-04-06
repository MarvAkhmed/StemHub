//
//  SettingsView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
            
            Button("Sign Out") {
                authVM.logout()
            }
            .foregroundColor(.red)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
