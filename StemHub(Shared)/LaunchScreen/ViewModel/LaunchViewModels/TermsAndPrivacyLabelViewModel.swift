//
//  TermsAndPrivacyLabelViewModel.swift
//  StemHub
//
//  Created by Marwa Awad on 29.03.2026.
//

import SwiftUI
import Combine

protocol TermsAndPrivacyLabelViewModelProtocol: ObservableObject {
    var attributedText: AttributedString { get }
}

class TermsAndPrivacyLabelViewModel: TermsAndPrivacyLabelViewModelProtocol {
    private let terms = "Terms of Use"
    private let privacyPolicy = "Privacy Policy"
    
    var attributedText: AttributedString {
        var attribute = AttributedString("By continuing, you agree to Git-Music’s  \(terms) and \(privacyPolicy)")
        attribute.foregroundColor = .white
        redirectToLink(fullStringAttribute: &attribute)
        return attribute
    }
}

extension TermsAndPrivacyLabelViewModel {
    private func redirectToLink(fullStringAttribute: inout AttributedString) {
        if let termsRange = fullStringAttribute.range(of: terms) {
            fullStringAttribute[termsRange].link = URL(string: AppURLs.termsOfUse)
            fullStringAttribute[termsRange].foregroundColor = .buttonBackground
        }
        
        if let privacyRange = fullStringAttribute.range(of: privacyPolicy) {
            fullStringAttribute[privacyRange].link = URL(string: AppURLs.privacyPolicy)
            fullStringAttribute[privacyRange].foregroundColor = .buttonBackground
        }
    }
}
