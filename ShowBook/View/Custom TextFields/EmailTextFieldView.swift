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
            .padding(.trailing, DesignMetric.p21)
            .fieldPlaceholder(when: email.isEmpty) {
                placeholderView
            }
            .frame(height: DesignMetric.p53)
    }

    private var placeholderView: some View {
        HStack(spacing: DesignMetric.p0) {
            Text(placeholderText)
                .foregroundColor(ShowBookTheme.colors.foreground)
                .font(Typography.title2)
            if mandatoryField {
                Text(" *")
                    .foregroundColor(DesignColor.red)
                    .font(Typography.title2)
            }
        }
    }
    
    private var profileIcon: some View {
        Image("ProfileIcon")
            .resizable()
            .frame(width: DesignMetric.p21, height: DesignMetric.p21)
            .padding(.vertical, Spacing.sixteen)
            .padding(.horizontal, DesignMetric.p19)
    }
    
    var body: some View {
        HStack(spacing: DesignMetric.p0) {
            profileIcon
            emailField
        }
    }
}

#Preview {
    EmailTextFieldView(email: .constant(""), placeholderText: "Email", mandatoryField: true)
}
