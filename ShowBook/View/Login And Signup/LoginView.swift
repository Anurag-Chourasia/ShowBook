//
//  LoginView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

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
                Image(systemName: "chevron.left")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .padding()
                    .foregroundStyle(Color(UIColor(hex: "#07629B")))
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color(UIColor(hex: "#07629B")), lineWidth: 2)
                    )
            }
            .padding(.top, 20)
            .padding(.leading, 20)
            Spacer()
        }
        .padding(.bottom, 30)
    }

    private var welcomeText: some View {
        HStack(spacing: 0) {
            Text("Welcome,\nlog in to continue")
                .font(.title)
                .padding(.leading, 30)
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
            RoundedRectangle(cornerRadius: 26.5)
                .stroke(Color(UIColor(hex: "#DADADA")), lineWidth: 1)
        )
        .padding(.bottom, 14)
        .padding(.horizontal, 34)
    }

    private var passwordField: some View {
        HStack(spacing: 0) {
            PasswordTextFieldView(text: $viewModel.password,
                                  placeholderText: "Password",
                                  mandatoryField: true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 26.5)
                .stroke(Color(UIColor(hex: "#DADADA")), lineWidth: 1)
        )
        .padding(.bottom, 20)
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
                    .background(RoundedRectangle(cornerRadius: 26.5))
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
        .foregroundStyle(Color(UIColor(hex: "#07629B")))
        .padding(.bottom, 18)
        .padding(.leading, 33)
        .padding(.trailing, 33)
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading.")
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width)
        .background(Color(UIColor(hex: "#FFFFFF")).opacity(0.5))
    }
}

#Preview {
    LoginView()
        .environmentObject(UserViewModel())
        .navigationViewStyle(StackNavigationViewStyle())
}
