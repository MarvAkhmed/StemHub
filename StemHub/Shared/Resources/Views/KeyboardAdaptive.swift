//
//  KeyboardAdaptive.swift
//  StemHub
//
//  Created by Marwa Awad on 31.03.2026.
//

import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

struct KeyboardAdaptive: ViewModifier {
    #if os(iOS)
    @State private var keyboardHeight: CGFloat = 0
    private let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    #endif
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(keyboardWillShow) { notification in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight = frame.height
                    }
                }
            }
            .onReceive(keyboardWillHide) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
        #else
        content 
        #endif
    }
}
