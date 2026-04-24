//
//  GradientTextField.swift
//  StemHub
//
//  Created by Marwa Awad on 30.03.2026.
//

import SwiftUI

struct GradientFocusTextField: View {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool = false
    var activeColor: Color = .buttonBackground
    @FocusState var isFocused: Bool
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            // Glassy / semi-transparent background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isFocused ? 0.25 : 0.1))
                .frame(height: 48)
            
            // Active stroke
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? activeColor : Color.clear, lineWidth: 2)
                .frame(height: 48)
            
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
            }
            
            HStack {
                if isSecure {
                    if isPasswordVisible {
#if os(iOS)
                        TextField("", text: $text)
                            .textInputAutocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isFocused)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .textFieldStyle(.plain)
#elseif os(macOS)
                        TextField("", text: $text)
                            .focused($isFocused)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .textFieldStyle(.plain)
#endif
                    } else {
#if os(iOS)
                        SecureField("", text: $text)
                            .textInputAutocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isFocused)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .textFieldStyle(.plain)
#elseif os(macOS)
                        SecureField("", text: $text)
                            .focused($isFocused)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .textFieldStyle(.plain)
#endif
                    }
                    
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 12)
                } else {
#if os(iOS)
                    TextField("", text: $text)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .textFieldStyle(.plain)
#elseif os(macOS)
                    TextField("", text: $text)
                        .focused($isFocused)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .textFieldStyle(.plain)
#endif
                }
            }
        }
    }
    
}
