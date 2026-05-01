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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                summary

                ForEach(changeSections, id: \.title) { section in
                    if section.files.isEmpty == false {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(section.title, systemImage: section.symbol)
                                    .font(.headline)
                                    .foregroundStyle(section.color)
                                Spacer()
                                Text("\(section.files.count)")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(section.color.opacity(0.14)))
                            }

                            ForEach(section.files, id: \.path) { fileDiff in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(section.color)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(fileDiff.path)
                                            .font(.subheadline.weight(.medium))

                                        if let oldPath = fileDiff.oldPath {
                                            Text("From \(oldPath)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        if let folder = folderName(for: fileDiff.path) {
                                            Text(folder)
                                                .font(.caption2.weight(.semibold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().fill(Color.secondary.opacity(0.10)))
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

private extension DiffPreviewView {
    struct ChangeSection {
        let title: String
        let symbol: String
        let color: Color
        let files: [FileDiff]
    }

    var summary: some View {
        HStack(spacing: 12) {
            summaryPill(title: "Added", count: diff.added.count, color: .green)
            summaryPill(title: "Changed", count: diff.modified.count, color: .orange)
            summaryPill(title: "Removed", count: diff.removed.count, color: .red)
            summaryPill(title: "Renamed", count: diff.renamed.count, color: .blue)
        }
    }

    var changeSections: [ChangeSection] {
        [
            ChangeSection(title: "Added Files", symbol: "plus.circle.fill", color: .green, files: diff.added),
            ChangeSection(title: "Modified Files", symbol: "slider.horizontal.3", color: .orange, files: diff.modified),
            ChangeSection(title: "Removed Files", symbol: "minus.circle.fill", color: .red, files: diff.removed),
            ChangeSection(title: "Renamed Files", symbol: "arrow.left.arrow.right.circle.fill", color: .blue, files: diff.renamed)
        ]
    }

    func summaryPill(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.secondary.opacity(0.10)))
    }

    func folderName(for path: String) -> String? {
        let folder = (path as NSString).deletingLastPathComponent
        return folder.isEmpty || folder == path ? nil : folder
    }
}
