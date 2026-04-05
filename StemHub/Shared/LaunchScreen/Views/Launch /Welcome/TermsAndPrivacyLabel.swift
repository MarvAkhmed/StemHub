//
//  TermsAndPrivacyLabel.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.03.2026.
//

import SwiftUI

struct TermsAndPrivacyLabel: View {
    var viewModel: any TermsAndPrivacyLabelViewModelProtocol
    
    var body: some View {
        Text(viewModel.attributedText)
            .font(.sanchezRegular16)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .truncationMode(.tail) 
            .fixedSize(horizontal: false, vertical: true)
    }
}
