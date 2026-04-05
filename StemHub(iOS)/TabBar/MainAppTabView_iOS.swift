//
//  MainAppTabView_iOS.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI


struct MainAppTabView_iOS<TabItem: Identifiable & Hashable>: View {
    
    @State private var selectedTab: TabItem.ID
    let tabs: [TabItem]
    let content: (TabItem) -> AnyView
    let label: (TabItem) -> Label<Text, Image>
    
    init(
        tabs: [TabItem],
        initialTab: TabItem.ID,
        @ViewBuilder content: @escaping (TabItem) -> some View,
        @ViewBuilder label: @escaping (TabItem) -> Label<Text, Image>
    ) {
        self.tabs = tabs
        self._selectedTab = State(initialValue: initialTab)
        self.content = { tab in AnyView(content(tab)) }
        self.label = label
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(tabs) { tab in
                content(tab)
                    .tabItem { label(tab) }
                    .tag(tab.id)
            }
        }
        .accentColor(.buttonBackground)
    }
}
