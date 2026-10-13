//
//  LoginView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import UIComponentsKit
import DesignTokensKit

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    ZStack {
                        VStack(spacing: 0) {
                            header
                            welcomeText
                            emailField
                            passwordField
                            loginButton
                            Spacer()
                        }
                        .frame(minHeight: geometry.size.height)
                        .opacity(viewModel.isLoading ? 0.2 : 1.0)

                        if viewModel.isLoading {
                            loadingView
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationViewStyle(StackNavigationViewStyle())
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
            Text("Welcome,\nlog in to continue")
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
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, Spacing.fourteen)
        .padding(.horizontal, 34)
    }

    private var passwordField: some View {
        HStack(spacing: 0) {
            PasswordTextFieldView(text: $viewModel.password,
                                  placeholderText: "Password",
                                  mandatoryField: true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, Spacing.twenty)
        .padding(.horizontal, 34)
    }

    private var loginButton: some View {
        HStack(spacing: 0) {
            Button(action: {
                viewModel.handleLogin(userViewModel: userViewModel)
            }) {
                Text("Login")
                    .font(.headline)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius))
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"),
                      message: Text(viewModel.errorMessage),
                      dismissButton: .default(Text("OK"), action: {
                    viewModel.isLoading = false
                }))
            }
            .onChange(of: viewModel.showAlert){
                if viewModel.showAlert {
                    UIApplication.shared.endEditing()
                }
            }
        }
        .foregroundStyle(ShowBookTheme.colors.action)
        .padding(.bottom, 18)
        .padding(.leading, 33)
        .padding(.trailing, 33)
    }

    private var loadingView: some View {
        CenteredProgressOverlay(width: UIScreen.main.bounds.width) {
            Text("Loading.")
        } background: {
            ShowBookTheme.colors.surface.opacity(0.5)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserViewModel())
        .navigationViewStyle(StackNavigationViewStyle())
}
