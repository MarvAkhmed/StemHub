//
//  MainAppTabView_iOS.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI

struct MainAppTabView_iOS: View {
    @State private var selectedTab: String
    let tabs: [AppTab]
    let content: (AppTab) -> AnyView
    
    init(
        tabs: [AppTab],
        initialTab: String,
        @ViewBuilder content: @escaping (AppTab) -> some View
    ) {
        self.tabs = tabs
        self._selectedTab = State(initialValue: initialTab)
        self.content = { tab in AnyView(content(tab)) }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(tabs) { tab in
                content(tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab.id)
            }
        }
        .accentColor(.buttonBackground)
    }
}
