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
        .padding(.trailing, \.p21)
        .fieldPlaceholder(when: text.isEmpty) {
            placeholderView
        }
        .frame(height: \.p53)
        .padding(.leading, \.p19)
    }

    private var placeholderView: some View {
        HStack(spacing: \.zero) {
            Text(placeholderText)
                .foregroundColor(ShowBookTheme.colors.foreground)
                .font(\.title2)
            if mandatoryField {
                Text(" *")
                    .foregroundColor(\.red)
                    .font(\.title2)
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
                .foregroundColor(\.gray)
                .frame(width: \.p20, height: \.p20)
                .padding(.leading, \.twenty)
                .padding(.trailing, \.p22_58)
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            passwordField
                .padding(.trailing, \.thirtyTwo)

            toggleVisibilityButton
        }
    }
}

#Preview {
    PasswordTextFieldView(text: .constant(""), placeholderText: "Password", mandatoryField: true)
}
