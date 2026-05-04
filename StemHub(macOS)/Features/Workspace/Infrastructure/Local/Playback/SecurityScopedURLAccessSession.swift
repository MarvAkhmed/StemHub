//
//  SecurityScopedURLAccessSession.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 02.05.2026.
//

import Foundation

protocol SecurityScopedURLAccessSession: AnyObject {
    func invalidate()
}

final class DefaultSecurityScopedURLAccessSession: SecurityScopedURLAccessSession {
   private let url: URL
   private let didStartAccess: Bool
   private var isActive = true

   init(url: URL) {
       self.url = url
       didStartAccess = url.startAccessingSecurityScopedResource()
   }

   deinit {
       invalidate()
   }

   func invalidate() {
       guard isActive else { return }
       isActive = false

       if didStartAccess {
           url.stopAccessingSecurityScopedResource()
       }
   }
}
