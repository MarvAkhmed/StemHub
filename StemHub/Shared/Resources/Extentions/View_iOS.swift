//
//  View_iOS.swift
//  StemHub
//
//  Created by Marwa Awad on 04.04.2026.
//

import SwiftUI

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
