//
//  AuthScreenScaffold.swift
//  StemHub
//
//  Created by Marwa Awad on 23.04.2026.
//

import SwiftUI

struct AuthScreenScaffold<Header: View, Fields: View, Actions: View, Footer: View>: View {
    private let actionsTopPaddingIOS: CGFloat
    private let actionsTopPaddingMacOS: CGFloat
    private let header: Header
    private let fields: Fields
    private let actions: Actions
    private let footer: Footer

    init(
        actionsTopPaddingIOS: CGFloat = 0,
        actionsTopPaddingMacOS: CGFloat = 30,
        @ViewBuilder header: () -> Header,
        @ViewBuilder fields: () -> Fields,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder footer: () -> Footer
    ) {
        self.actionsTopPaddingIOS = actionsTopPaddingIOS
        self.actionsTopPaddingMacOS = actionsTopPaddingMacOS
        self.header = header()
        self.fields = fields()
        self.actions = actions()
        self.footer = footer()
    }

    var body: some View {
        ZStack {
            backgroundLayer
            content
        }
    }

    private var backgroundLayer: some View {
        Color.background
            .opacity(0.6)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var content: some View {
        #if os(iOS)
        iosContent
        #elseif os(macOS)
        macOSContent
        #endif
    }

    #if os(iOS)
    private var iosContent: some View {
        GeometryReader { proxy in
            let topPadding = max(24, proxy.safeAreaInsets.top + 8)
            let bottomPadding = max(24, proxy.safeAreaInsets.bottom + 12)
            let minimumContentHeight = max(0, proxy.size.height - topPadding - bottomPadding)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .platformPadding(.bottom, iOS: 32, macOS: 0)

                    fields
                        .platformPadding(.horizontal, iOS: 40, macOS: 0)

                    actions
                        .platformPadding(.top, iOS: actionsTopPaddingIOS, macOS: actionsTopPaddingMacOS)

                    footer
                        .padding(.top, 28)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .frame(minHeight: minimumContentHeight, alignment: .top)
            }
        }
    }
    #endif

    #if os(macOS)
    private var macOSContent: some View {
        VStack {
            Spacer()
            header
                .platformPadding(.bottom, iOS: 40, macOS: 0)
            Spacer()

            VStack {
                fields
                    .platformPadding(.horizontal, iOS: 40, macOS: 0)
                actions
                    .platformPadding(.top, iOS: actionsTopPaddingIOS, macOS: actionsTopPaddingMacOS)
                Spacer()
            }
            .platformPadding(.horizontal, iOS: 0, macOS: 30)

            Spacer()
            footer
            Spacer()
        }
        .platformPadding(iOS: 0, macOS: 200)
        .platformPadding(.top, iOS: 0, macOS: 45)
    }
    #endif
}
