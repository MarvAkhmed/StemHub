//
//  DefaultFirestoreProjectStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore

protocol FirestoreProjectStrategy {
    func fetchProjects(for bandID: String) async throws -> [Project]
    func fetchAllProjects(for userID: String) async throws -> [Project]
    func fetchProject(projectID: String) async throws -> Project?
    func createProject(_ project: Project) async throws
    func updateProject(_ project: Project) async throws
}

struct DefaultFirestoreProjectStrategy: FirestoreProjectStrategy {
    private let db = Firestore.firestore()
    
    func fetchProjects(for bandID: String) async throws -> [Project] {
        let snapshot = try await db.collection("projects")
            .whereField("bandID", isEqualTo: bandID)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Project.self) }
    }
    
    func fetchAllProjects(for userID: String) async throws -> [Project] {
        let userDoc = try await db.collection("users").document(userID).getDocument()
        guard let user = try? userDoc.data(as: User.self) else { return [] }
        
        var allProjects: [Project] = []
        for bandID in user.bandIDs {
            let projects = try await fetchProjects(for: bandID)
            allProjects.append(contentsOf: projects)
        }
        return allProjects
    }
    
    func fetchProject(projectID: String) async throws -> Project? {
        let doc = try await db.collection("projects").document(projectID).getDocument()
        return try? doc.data(as: Project.self)
    }
    
    func createProject(_ project: Project) async throws {
        try db.collection("projects").document(project.id).setData(from: project)
    }
    
    func updateProject(_ project: Project) async throws {
        try db.collection("projects").document(project.id).setData(from: project, merge: true)
    }
}
