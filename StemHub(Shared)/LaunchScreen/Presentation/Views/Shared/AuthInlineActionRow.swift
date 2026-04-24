//
//  AuthInlineActionRow.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct AuthInlineActionRow: View {
    let prefixText: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(prefixText)
                .font(.sanchezRegular16)
                .foregroundColor(.buttonBackground)

            Button(action: action) {
                Text(actionTitle)
                    .font(.sanchezRegular16)
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
    }
}
