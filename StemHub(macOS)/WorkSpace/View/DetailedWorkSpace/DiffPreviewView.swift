//
//  DiffPreviewView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI

// MARK: - Diff Preview View
struct DiffPreviewView: View {
    let diff: ProjectDiff
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(diff.files, id: \.path) { fileDiff in
                    HStack {
                        changeTypeIcon(fileDiff.changeType)
                            .foregroundColor(colorForChangeType(fileDiff.changeType))
                        Text(fileDiff.path)
                            .font(.caption)
                        Spacer()
                        if fileDiff.changeType == .renamed, let oldPath = fileDiff.oldPath {
                            Text("from: \(oldPath)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
    }
    
    private func changeTypeIcon(_ type: ChangeType) -> some View {
        switch type {
        case .added:
            return Image(systemName: "plus.circle.fill")
        case .removed:
            return Image(systemName: "minus.circle.fill")
        case .modified:
            return Image(systemName: "pencil.circle.fill")
        case .renamed:
            return Image(systemName: "arrow.left.arrow.right.circle.fill")
        }
    }
    
    private func colorForChangeType(_ type: ChangeType) -> Color {
        switch type {
        case .added:
            return .green
        case .removed:
            return .red
        case .modified:
            return .orange
        case .renamed:
            return .blue
        }
    }
}


//
//struct DiffPreviewView: View {
//    let diff: ProjectDiff
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Changes from current version")
//                .font(.headline)
//                .padding(.horizontal)
//
//            Divider()  
//
//            List {
//                ForEach(diff.files, id: \.path) { fileDiff in
//                    DiffChangeRow(diff: fileDiff)
//                }
//            }
//        }
//        .frame(height: 200)
//    }
//}
