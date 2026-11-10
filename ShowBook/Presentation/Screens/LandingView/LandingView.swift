//
//  LandingView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import DesignTokensKit
import LocalizationKit
import AuthKitUI

struct LandingView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showingAuthSheet = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: \.zero) {
                headerView
                Spacer()
                logoView
                Spacer()
                navigationButtons
            }
            .navigationTitle(\.welcomeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .showBookTools()
            .sheet(isPresented: $showingAuthSheet) {
                AppAuthGate(brand: .showBook) { user, _ in
                    Text(user.email ?? "")
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            VStack {
                Text(\ShowBookStrings.appName)
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

            Button {
                showingAuthSheet = true
            } label: {
                Text(\.authTitleSignIn)
                    .font(\.headline)
                    .frame(minWidth: \.p80)
                    .padding(\.sixteen)
                    .background(\.blue)
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
