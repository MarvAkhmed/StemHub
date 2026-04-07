//
//  VersionRowView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation
import SwiftUI


struct VersionRowView: View {
    let version: ProjectVersion
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Version \(version.versionNumber)")
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(version.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

//struct VersionRowView: View {
//    let version: ProjectVersion
//    let isSelected: Bool
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Version \(version.versionNumber)")
//                    .font(.headline)
//                    .foregroundColor(isSelected ? .white : .primary)
//
//                Text(version.createdAt, style: .date)
//                    .font(.caption)
//                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
//
//                if let notes = version.notes, !notes.isEmpty {
//                    Text(notes)
//                        .font(.caption2)
//                        .lineLimit(1)
//                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
//                }
//            }
//
//            Spacer()
//
//            if version.fileVersionIDs.count > 0 {
//                Text("\(version.fileVersionIDs.count) files")
//                    .font(.caption2)
//                    .padding(4)
//                    .background(Capsule().fill(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.2)))
//            }
//        }
//        .padding(.vertical, 4)
//        .contentShape(Rectangle())
//    }
//}


//struct VersionRowView: View {
//    let version: ProjectVersion
//    let isSelected: Bool
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Version \(version.versionNumber)")
//                    .font(.headline)
//                    .foregroundColor(isSelected ? .white : .primary)
//                
//                Text(version.createdAt, style: .date)
//                    .font(.caption)
//                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
//                
//                if let notes = version.notes, !notes.isEmpty {
//                    Text(notes)
//                        .font(.caption2)
//                        .lineLimit(1)
//                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
//                }
//            }
//            
//            Spacer()
//            
//            if version.fileVersionIDs.count > 0 {
//                Text("\(version.fileVersionIDs.count) files")
//                    .font(.caption2)
//                    .padding(4)
//                    .background(Capsule().fill(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.2)))
//            }
//        }
//        .padding(.vertical, 4)
//        .contentShape(Rectangle())
//    }
//}
