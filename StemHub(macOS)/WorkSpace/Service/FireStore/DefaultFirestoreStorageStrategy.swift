//
//  DefaultFirestoreStorageStrategy.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

protocol FirestoreStorageStrategy {
    func uploadProjectPoster(projectID: String, image: NSImage) async throws -> String
    func updateProjectPoster(projectID: String, posterURL: String) async throws
}

struct DefaultFirestoreStorageStrategy: FirestoreStorageStrategy {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    #if os(macOS)

    func uploadProjectPoster(projectID: String, image: NSImage) async throws -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(projectID)_\(timestamp).png"
        let storageRef = Storage.storage().reference().child("projectPosters/\(fileName)")
        
        guard let data = image.tiffRepresentation,
              let pngData = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "ImageConversion", code: -1)
        }
        
        // Direct upload – no delete, no metadata check
        _ = try await storageRef.putDataAsync(pngData)
        let url = try await storageRef.downloadURL()
        
        // Update the project with this new URL
        try await db.collection("projects").document(projectID).updateData([
            "posterURL": url.absoluteString
        ])
        
        return url.absoluteString
    }
    #endif
    
    #if os(iOS)
    func uploadProjectPoster(projectID: String, image: Any) async throws -> String {
        guard let uiImage = image as? UIImage,
              let pngData = uiImage.pngData() else {
            throw NSError(domain: "Image conversion failed", code: -1)
        }
        
        let storageRef = storage.reference().child("projectPosters/\(projectID).png")
        _ = try await storageRef.putDataAsync(pngData)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
    #endif
    
    func updateProjectPoster(projectID: String, posterURL: String) async throws {
        try await db.collection("projects").document(projectID).updateData([
            "posterURL": posterURL
        ])
    }
}

