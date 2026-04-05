//
//  DiffPreviewView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI

struct DiffPreviewView: View {
    let diff: ProjectDiff

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Changes from current version")
                .font(.headline)
                .padding(.horizontal)

            Divider()  

            List {
                ForEach(diff.files, id: \.path) { fileDiff in
                    DiffChangeRow(diff: fileDiff)
                }
            }
        }
        .frame(height: 200)
    }
}
