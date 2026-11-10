//
//  EmailTextFieldView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import LocalizationKit
import UIComponentsKit
import DesignTokensKit

struct EmailTextFieldView: View {
    @Binding var email: String
    let placeholderText: String
    let mandatoryField: Bool
    
    private var emailField: some View {
        TextField("", text: $email)
            .padding(.trailing, \.p21)
            .fieldPlaceholder(when: email.isEmpty) {
                placeholderView
            }
            .frame(height: \.p53)
    }

    private var placeholderView: some View {
        HStack(spacing: \.zero) {
            Text(placeholderText)
                .foregroundColor(ColorTheme.default.primary)
                .font(\.title2)
            if mandatoryField {
                Text(" *")
                    .foregroundColor(\.red)
                    .font(\.title2)
            }
        }
    }
    
    private var profileIcon: some View {
        Image("ProfileIcon")
            .resizable()
            .frame(width: \.p21, height: \.p21)
            .padding(.vertical, \.sixteen)
            .padding(.horizontal, \.p19)
    }
    
    var body: some View {
        HStack(spacing: \.zero) {
            profileIcon
            emailField
        }
    }
}

#Preview {
    EmailTextFieldView(email: .constant(""), placeholderText: String(\CommonStrings.authFieldEmail), mandatoryField: true)
}
