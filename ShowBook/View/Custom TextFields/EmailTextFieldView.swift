//
//  EmailTextFieldView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import UIComponentsKit
import DesignTokensKit

struct EmailTextFieldView: View {
    @Binding var email: String
    let placeholderText: String
    let mandatoryField: Bool
    
    private var emailField: some View {
        TextField("", text: $email)
            .padding(.trailing, 21)
            .fieldPlaceholder(when: email.isEmpty) {
                placeholderView
            }
            .frame(height: 53)
    }

    private var placeholderView: some View {
        HStack(spacing: 0) {
            Text(placeholderText)
                .foregroundColor(ShowBookTheme.colors.foreground)
                .font(.title2)
            if mandatoryField {
                Text(" *")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
    }
    
    private var profileIcon: some View {
        Image("ProfileIcon")
            .resizable()
            .frame(width: 21, height: 21)
            .padding(.vertical, Spacing.sixteen)
            .padding(.horizontal, 19)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            profileIcon
            emailField
        }
    }
}

#Preview {
    EmailTextFieldView(email: .constant(""), placeholderText: "Email", mandatoryField: true)
}
