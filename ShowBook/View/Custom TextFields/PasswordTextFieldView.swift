//
//  PasswordTextFieldView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

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
        .padding(.trailing, 21)
        .placeholder(when: text.isEmpty) {
            placeholderView
        }
        .frame(height: 53)
        .padding(.leading, 19)
    }

    private var placeholderView: some View {
        HStack(spacing: 0) {
            Text(placeholderText)
                .foregroundColor(Color(UIColor(hex: "#242E3D")))
                .font(.title2)
            if mandatoryField {
                Text(" *")
                    .foregroundColor(.red)
                    .font(.title2)
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
                .foregroundColor(.gray)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .padding(.trailing, 22.58)
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            passwordField
                .padding(.trailing, 32)

            toggleVisibilityButton
        }
    }
}

#Preview {
    PasswordTextFieldView(text: .constant(""), placeholderText: "Password", mandatoryField: true)
}
