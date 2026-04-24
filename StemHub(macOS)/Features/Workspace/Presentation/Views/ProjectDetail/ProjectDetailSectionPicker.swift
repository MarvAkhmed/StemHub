//
//  ProjectDetailSectionPicker.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct ProjectDetailSectionPicker: View {
    @Binding var selection: ProjectDetailSection

    var body: some View {
        Picker("Detail Section", selection: $selection) {
            ForEach(ProjectDetailSection.allCases) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
    }
}

