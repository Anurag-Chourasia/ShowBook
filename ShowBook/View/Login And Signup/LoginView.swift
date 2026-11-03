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
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    VStack(spacing: \.zero) {
                        welcomeText
                        emailField
                        passwordField
                        loginButton
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .opacity(viewModel.isLoading ? OpacityTheme.default.p0_2 : OpacityTheme.default.p1_0)

                    if viewModel.isLoading {
                        loadingView
                    }
                }
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .showBookTools()
    }

    private var welcomeText: some View {
        HStack(spacing: \.zero) {
            Text("Welcome,\nlog in to continue")
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
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.fourteen)
        .padding(.horizontal, \.p34)
    }

    private var passwordField: some View {
        HStack(spacing: \.zero) {
            PasswordTextFieldView(text: $viewModel.password,
                                  placeholderText: "Password",
                                  mandatoryField: true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.twenty)
        .padding(.horizontal, \.p34)
    }

    private var loginButton: some View {
        HStack(spacing: \.zero) {
            Button(action: {
                viewModel.handleLogin(userViewModel: userViewModel)
            }) {
                Text("Login")
                    .font(\.headline)
                    .frame(height: \.p55)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(\.white)
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
        .padding(.bottom, \.p18)
        .padding(.leading, \.p33)
        .padding(.trailing, \.p33)
    }

    private var loadingView: some View {
        CenteredProgressOverlay(width: UIScreen.main.bounds.width) {
            Text("Loading.")
        } background: {
            ShowBookTheme.colors.surface.opacity(OpacityTheme.default.p0_5)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView().environmentObject(UserViewModel())
    }
}
