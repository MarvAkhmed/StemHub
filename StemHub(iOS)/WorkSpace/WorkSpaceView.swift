//
//  WorkSpaceView.swift
//  StemHub(iOS)
//
//  Created by Marwa Awad on 01.04.2026.
//

import SwiftUI

struct WorkSpaceView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    
    var body: some View {
        VStack {
            Text("Welcome to Workspace")
                .font(.title)
            
            Button("Logout") {
                viewModel.logout()
            }
            .padding()
        }
    }
}
