//
//  KeyboardAdaptive.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI
import Combine
import UIKit

struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    private let keyboardWillChangeFrame = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(keyboardWillChangeFrame, perform: updateKeyboardHeight)
            .onReceive(keyboardWillHide) { _ in
                setKeyboardHeight(to: 0)
            }
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let windowHeight = keyWindow?.bounds.height ?? UIScreen.main.bounds.height
        let adjustedHeight = max(0, windowHeight - frame.minY - bottomSafeAreaInset)
        setKeyboardHeight(to: adjustedHeight)
    }

    private func setKeyboardHeight(to newValue: CGFloat) {
        withAnimation(.easeOut(duration: 0.25)) {
            keyboardHeight = newValue
        }
    }

    private var bottomSafeAreaInset: CGFloat {
        keyWindow?.safeAreaInsets.bottom ?? 0
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)
    }
}
