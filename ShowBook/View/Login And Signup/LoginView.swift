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
                    VStack(spacing: DesignMetric.p0) {
                        welcomeText
                        emailField
                        passwordField
                        loginButton
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .opacity(viewModel.isLoading ? OpacityToken.p0_2 : OpacityToken.p1_0)

                    if viewModel.isLoading {
                        loadingView
                    }
                }
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var welcomeText: some View {
        HStack(spacing: DesignMetric.p0) {
            Text("Welcome,\nlog in to continue")
                .font(Typography.title)
                .padding(.leading, Spacing.thirty)
            Spacer()
        }
        .padding(.top, Spacing.twenty)
        .padding(.bottom, DesignMetric.p50)
    }

    private var emailField: some View {
        HStack(spacing: DesignMetric.p0) {
            EmailTextFieldView(email: $viewModel.email,
                               placeholderText: "Email",
                               mandatoryField: true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, Spacing.fourteen)
        .padding(.horizontal, DesignMetric.p34)
    }

    private var passwordField: some View {
        HStack(spacing: DesignMetric.p0) {
            PasswordTextFieldView(text: $viewModel.password,
                                  placeholderText: "Password",
                                  mandatoryField: true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, Spacing.twenty)
        .padding(.horizontal, DesignMetric.p34)
    }

    private var loginButton: some View {
        HStack(spacing: DesignMetric.p0) {
            Button(action: {
                viewModel.handleLogin(userViewModel: userViewModel)
            }) {
                Text("Login")
                    .font(Typography.headline)
                    .frame(height: DesignMetric.p55)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(DesignColor.white)
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
        .padding(.bottom, DesignMetric.p18)
        .padding(.leading, DesignMetric.p33)
        .padding(.trailing, DesignMetric.p33)
    }

    private var loadingView: some View {
        CenteredProgressOverlay(width: UIScreen.main.bounds.width) {
            Text("Loading.")
        } background: {
            ShowBookTheme.colors.surface.opacity(OpacityToken.p0_5)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView().environmentObject(UserViewModel())
    }
}
