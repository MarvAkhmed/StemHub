//
//  ProjectCardViewModel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Combine
import SwiftUI

protocol ProjectCardViewModelProtocol: ObservableObject {
    var project: Project { get }
    var name: String { get }
    var projectPosterImage: NSImage? { get }
    var updatedAtFormatted: String { get }
    var bandIDPrefix: String { get }
    var versionPrefix: String { get }
    var posterURL: URL? { get }
}

final class ProjectCardViewModel: ProjectCardViewModelProtocol {
    @Published var project: Project
    var name: String { project.name }
    
    var projectPosterImage: NSImage? {
        guard let base64 = project.posterBase64,
              let data = Data(base64Encoded: base64) else { return nil }
        return NSImage(data: data)
    }
    
    var updatedAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: project.updatedAt)
    }
    var bandIDPrefix: String { String(project.bandID.prefix(8)) }
    var versionPrefix: String { "v\(project.currentVersionID.prefix(6))" }
    var posterURL: URL? {
        guard let string = project.posterURL else { return nil }
        return URL(string: string)
    }
    
    init(project: Project) {
        self.project = project
    }
}
