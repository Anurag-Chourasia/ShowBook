//
//  SignUpView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
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
        .navigationTitle("Sign Up")
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
            Text("Welcome,\nSign up to continue")
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
                               placeholderText: "Email",
                               mandatoryField: true)
        }
        .background(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.twenty)
        .padding(.horizontal, \.p34)
    }

    private var passwordField: some View {
        HStack(spacing: \.zero) {
            PasswordTextFieldView(text: $viewModel.password,
                                  placeholderText: "Password",
                                  mandatoryField: true)
        }
        .background(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.twenty)
        .padding(.horizontal, \.p34)
    }

    private var passwordRequirements: some View {
        VStack(alignment: .leading) {
            requirementItem(isValidEmail(viewModel.email), text: "Must be a valid email")
            requirementItem(viewModel.password.hasUppercaseCharacter, text: "Must contain an uppercase")
            requirementItem(viewModel.password.hasLowercaseCharacter, text: "Must contain a lowercase")
            requirementItem(viewModel.password.hasSpecialCharacter, text: "Must contain a special character")
            requirementItem(viewModel.password.hasNumberCharacter, text: "Must contain a number character")
            requirementItem(viewModel.password.count >= 8, text: "At least 8 characters")
        }
        .padding(.horizontal, \.twenty)
    }

    private func requirementItem(_ isValid: Bool, text: String) -> some View {
        HStack {
            Image(systemName: isValid ? "checkmark.square" : "square")
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
                Text("Sign Up")
                    .font(\.headline)
                    .frame(height: \.p55)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(\.white)
                    .background(RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius))
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"),
                      message: Text("\(viewModel.errorMessage)"),
                      dismissButton: .default(Text("OK"), action: {
                    viewModel.isLoading = false
                }))
            }
            .onChange(of: viewModel.showAlert) {
                if viewModel.showAlert {
                    UIApplication.shared.endEditing()
                }
            }
            
        
        }
        .foregroundColor(ShowBookTheme.colors.action)
        .padding(.vertical, \.p18)
        .padding(.horizontal, \.p33)
    }

    private var loadingOverlay: some View {
        CenteredProgressOverlay(width: UIScreen.main.bounds.width) {
            Text("Loading.")
        } background: {
            ShowBookTheme.colors.surface.opacity(OpacityTheme.default.p0_5)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView().environmentObject(UserViewModel())
    }
}
