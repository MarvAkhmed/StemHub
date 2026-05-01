//
//  IOSMetricPill.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 25.04.2026.
//

import Foundation
import SwiftUI

struct IOSMetricPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(IOSStudioPalette.mutedText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.10))
        )
    }
}
