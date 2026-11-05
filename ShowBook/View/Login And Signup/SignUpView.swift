//
//  SignUpView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import LocalizationKit
import UIComponentsKit
import DesignTokensKit

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                content
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
        .onAppear(perform: viewModel.loadData)
        .onDisappear { viewModel.cancelCountryRequest() }
        .navigationTitle(String(\CommonStrings.authTitleCreateAccount))
        .navigationBarTitleDisplayMode(.inline)
        .showBookTools()
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: \.zero) {
                welcomeText
                Spacer()
                emailField
                passwordField
                passwordRequirements
                if !viewModel.countries.isEmpty && !viewModel.isLoading {
                    WheelPickerView(selectedCountryIndex: $viewModel.selectedCountryIndex, country: viewModel.countries)
                        .padding(.vertical, \.sixteen)
                }
                signUpButton
                Spacer()
            }
            .opacity(viewModel.isLoading ? OpacityTheme.default.p0_2 : OpacityTheme.default.p1_0)
        }
    }

    private var welcomeText: some View {
        HStack(spacing: \.zero) {
            Text(String(\ShowBookStrings.authSignupWelcome))
                .font(\.title)
                .padding(.leading, \.thirty)
            Spacer()
        }
        .padding(.top, \.twenty)
        .padding(.bottom, \.p50)
    }

    private var emailField: some View {
        HStack(spacing: \.zero) {
            EmailTextFieldView(email: $viewModel.email,
                               placeholderText: String(\CommonStrings.authFieldEmail),
                               mandatoryField: true)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignMetricTheme.default.p26_5)
                .stroke(ColorTheme.default.secondary, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.twenty)
        .padding(.horizontal, \.p34)
    }

    private var passwordField: some View {
        HStack(spacing: \.zero) {
            PasswordTextFieldView(text: $viewModel.password,
                                  placeholderText: String(\CommonStrings.authFieldPassword),
                                  mandatoryField: true)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignMetricTheme.default.p26_5)
                .stroke(ColorTheme.default.secondary, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.twenty)
        .padding(.horizontal, \.p34)
    }

    private var passwordRequirements: some View {
        VStack(alignment: .leading) {
            requirementItem(isValidEmail(viewModel.email), text: String(\ShowBookStrings.authValidEmail))
            requirementItem(viewModel.password.hasUppercaseCharacter, text: String(\ShowBookStrings.authUppercase))
            requirementItem(viewModel.password.hasLowercaseCharacter, text: String(\ShowBookStrings.authLowercase))
            requirementItem(viewModel.password.hasSpecialCharacter, text: String(\ShowBookStrings.authSpecial))
            requirementItem(viewModel.password.hasNumberCharacter, text: String(\ShowBookStrings.authNumber))
            requirementItem(viewModel.password.count >= 8, text: String(\ShowBookStrings.authLength))
        }
        .padding(.horizontal, \.twenty)
    }

    private func requirementItem(_ isValid: Bool, text: String) -> some View {
        HStack {
            Image(isValid ? \.checkmarkSquare : \.square)
            Text(text)
            Spacer()
        }
        .padding(.vertical, \.five)
    }

    private var signUpButton: some View {
        HStack(spacing: \.zero) {
            Button(action:{ 
                viewModel.handleSignUp(userViewModel: userViewModel)
            }) {
                Text(String(\CommonStrings.authTitleCreateAccount))
                    .font(\.headline)
                    .frame(height: \.p55)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(\.white)
                    .background(RoundedRectangle(cornerRadius: DesignMetricTheme.default.p26_5))
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text(String(\ShowBookStrings.alertError)),
                      message: Text("\(viewModel.errorMessage)"),
                      dismissButton: .default(Text(String(\CommonStrings.ok)), action: {
                    viewModel.isLoading = false
                }))
            }
            .onChange(of: viewModel.showAlert) {
                if viewModel.showAlert {
                    UIApplication.shared.endEditing()
                }
            }
            
        
        }
        .foregroundColor(ColorTheme.default.oceanAction)
        .padding(.vertical, \.p18)
        .padding(.horizontal, \.p33)
    }

    private var loadingOverlay: some View {
        CenteredProgressOverlay(width: UIScreen.main.bounds.width) {
            Text(String(\ShowBookStrings.loadingProgress))
        } background: {
            ColorTheme.default.groupedSecondary.opacity(OpacityTheme.default.p0_5)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView().environmentObject(UserViewModel())
    }
}
