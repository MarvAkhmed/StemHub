//
//  DiffChangeRow.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI

struct DiffChangeRow: View {
    let diff: FileDiff
    
    var body: some View {
        HStack {
            Image(systemName: iconForChangeType)
                .foregroundColor(colorForChangeType)
                .frame(width: 20)
            
            Text(diff.path)
                .font(.caption)
            
            if diff.changeType == .renamed, let oldPath = diff.oldPath {
                Text("(was: \(oldPath))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(changeTypeText)
                .font(.caption)
                .padding(4)
                .background(Capsule().fill(colorForChangeType.opacity(0.2)))
        }
        .padding(.vertical, 2)
    }
    
    private var iconForChangeType: String {
        switch diff.changeType {
        case .added: return "plus.circle.fill"
        case .removed: return "minus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .renamed: return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    private var colorForChangeType: Color {
        switch diff.changeType {
        case .added: return .green
        case .removed: return .red
        case .modified: return .orange
        case .renamed: return .blue
        }
    }
    
    private var changeTypeText: String {
        switch diff.changeType {
        case .added: return "Added"
        case .removed: return "Removed"
        case .modified: return "Modified"
        case .renamed: return "Renamed"
        }
    }
}

