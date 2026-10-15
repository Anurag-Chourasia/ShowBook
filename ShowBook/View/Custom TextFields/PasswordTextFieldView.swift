//
//  PasswordTextFieldView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import UIComponentsKit
import DesignTokensKit

struct PasswordTextFieldView: View {
    @Binding private var text: String
    @State private var isSecured: Bool = true
    let placeholderText: String
    let mandatoryField: Bool

    init(text: Binding<String>, placeholderText: String, mandatoryField: Bool) {
        self._text = text
        self.placeholderText = placeholderText
        self.mandatoryField = mandatoryField
    }

    private var passwordField: some View {
        Group {
            if isSecured {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
        .padding(.trailing, DesignMetric.p21)
        .fieldPlaceholder(when: text.isEmpty) {
            placeholderView
        }
        .frame(height: DesignMetric.p53)
        .padding(.leading, DesignMetric.p19)
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

    private var toggleVisibilityButton: some View {
        Button(action: {
            isSecured.toggle()
        }) {
            Image(systemName: isSecured ? "eye" : "eye.slash")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(DesignColor.gray)
                .frame(width: DesignMetric.p20, height: DesignMetric.p20)
                .padding(.leading, Spacing.twenty)
                .padding(.trailing, DesignMetric.p22_58)
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            passwordField
                .padding(.trailing, Spacing.thirtyTwo)

            toggleVisibilityButton
        }
    }
}

#Preview {
    PasswordTextFieldView(text: .constant(""), placeholderText: "Password", mandatoryField: true)
}
