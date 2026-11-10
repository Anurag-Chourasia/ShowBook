import DesignTokensKit
//
//  LandingView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import LocalizationKit
import CoreData

struct LandingView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {

        NavigationStack {

            VStack(alignment: .center, spacing: \.zero) {

                headerView

                Spacer()

                logoView

                Spacer()

                navigationButtons

            }
            .navigationTitle(String(\ShowBookStrings.welcomeTitle))
            .navigationBarTitleDisplayMode(.inline)
            .showBookTools()
        }

    }

    private var headerView: some View {
        HStack {
            Spacer()
            VStack{
                Text(String(\ShowBookStrings.appName))
                    .font(\.largeTitle)
            }
            Spacer()
        }
        .padding(.top, \.p50)
    }

    private var logoView: some View {
        GeometryReader { geo in
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geo.size.width - DesignMetricTheme.default.p80, DesignMetricTheme.default.p400), height: geo.size.height)
                    .clipShape(Circle())
            }
            .frame(width: geo.size.width, alignment: .center)
        }
    }

    private var navigationButtons: some View {
        HStack {
            Spacer()

            NavigationLink(destination: SignUpView(persistenceController: userViewModel.persistenceController)) {
                Text(String(\CommonStrings.authTitleCreateAccount))
                    .font(\.headline)
                    .frame(minWidth: \.p80)
                    .padding(\.sixteen)
                    .background(\.blue)
                    .foregroundColor(\.white)
                    .cornerRadius(\.eight)
            }

            Spacer()

            NavigationLink(destination: LoginView(persistenceController: userViewModel.persistenceController)) {
                Text(String(\CommonStrings.authTitleSignIn))
                    .font(\.headline)
                    .frame(minWidth: \.p80)
                    .padding(\.sixteen)
                    .background(\.green)
                    .foregroundColor(\.white)
                    .cornerRadius(\.eight)
            }

            Spacer()
        }
        .padding(.bottom, \.p50)
    }
}

#Preview {
    LandingView()
        .environmentObject(UserViewModel())
}
