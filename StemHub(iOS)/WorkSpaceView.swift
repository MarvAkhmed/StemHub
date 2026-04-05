//
//  WorkSpaceView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 01.04.2026.
//

import Foundation
import SwiftUI

struct WorkSpaceView: View {
    var body: some View {
        Button {
            GoogleAuthService.shared.logout()
        } label: {
           Text( "Logout")
        }

    }
}
