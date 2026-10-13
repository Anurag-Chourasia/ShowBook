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
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    content
                    if viewModel.isLoading {
                        loadingOverlay
                    }
                }
            }
            .onAppear(perform: viewModel.loadData)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                welcomeText
                Spacer()
                emailField
                passwordField
                passwordRequirements
                if !viewModel.countries.isEmpty && !viewModel.isLoading {
                    WheelPickerView(selectedCountryIndex: $viewModel.selectedCountryIndex, country: viewModel.countries)
                        .padding(.vertical)
                }
                signUpButton
                Spacer()
            }
            .opacity(viewModel.isLoading ? 0.2 : 1.0)
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                OutlinedIconLabel(systemImage: "chevron.left", color: ShowBookTheme.colors.action)
            }
            .padding(.top, Spacing.twenty)
            .padding(.leading, Spacing.twenty)
            Spacer()
        }
        .padding(.bottom, Spacing.thirty)
    }

    private var welcomeText: some View {
        HStack(spacing: 0) {
            Text("Welcome,\nSign up to continue")
                .font(.title)
                .padding(.leading, Spacing.thirty)
            Spacer()
        }
        .padding(.bottom, 50)
    }

    private var emailField: some View {
        HStack(spacing: 0) {
            EmailTextFieldView(email: $viewModel.email,
                               placeholderText: "Email",
                               mandatoryField: true)
        }
        .background(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, Spacing.twenty)
        .padding(.horizontal, 34)
    }

    private var passwordField: some View {
        HStack(spacing: 0) {
            PasswordTextFieldView(text: $viewModel.password,
                                  placeholderText: "Password",
                                  mandatoryField: true)
        }
        .background(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, Spacing.twenty)
        .padding(.horizontal, 34)
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
        .padding(.horizontal, Spacing.twenty)
    }

    private func requirementItem(_ isValid: Bool, text: String) -> some View {
        HStack {
            Image(systemName: isValid ? "checkmark.square" : "square")
            Text(text)
            Spacer()
        }
        .padding(.vertical, Spacing.five)
    }

    private var signUpButton: some View {
        HStack(spacing: 0) {
            Button(action:{ 
                viewModel.handleSignUp(userViewModel: userViewModel)
            }) {
                Text("Sign Up")
                    .font(.headline)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
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
        .padding(.vertical, 18)
        .padding(.horizontal, 33)
    }

    private var loadingOverlay: some View {
        CenteredProgressOverlay(width: UIScreen.main.bounds.width) {
            Text("Loading.")
        } background: {
            ShowBookTheme.colors.surface.opacity(0.5)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(UserViewModel())
        .navigationViewStyle(StackNavigationViewStyle())
}
