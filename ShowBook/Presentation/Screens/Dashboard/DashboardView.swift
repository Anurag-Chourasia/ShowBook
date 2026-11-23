//
//  DashboardView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import LocalizationKit
import UIComponentsKit
import DesignTokensKit

@MainActor
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    init(viewModel: @autoclosure @escaping () -> DashboardViewModel = DashboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: \.zero) {
                    DashboardSearchField(viewModel: viewModel)
                    contentStack
                    Spacer()
                }
                .navigationTitle(\ShowBookStrings.appName)
                .showBookTools(onLogout: { viewModel.logOutAlert = true })
                .navigationBarTitleDisplayMode(.inline)
                .alert(isPresented: $viewModel.showAlert) { errorAlert }
                .alert(isPresented: $viewModel.logOutAlert) { logoutAlert }
                if viewModel.isLoading { loadingOverlay }
            }
            .background(\.background)
        }
    }

    @ViewBuilder
    private var contentStack: some View {
        ZStack {
            if !viewModel.filteredBooks.isEmpty {
                VStack {
                    DashboardSortFilterBar(viewModel: viewModel)
                    DashboardBooksListView(viewModel: viewModel)
                }
            }
            if viewModel.filteredBooks.isEmpty && !viewModel.isBookLoading {
                if viewModel.searchBook.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && AppRuntime.discoverEnabled {
                    DiscoverView()
                } else {
                    DashboardSearchStateBanner(viewModel: viewModel)
                }
            }
            if viewModel.isBookLoading { loadingOverlay }
        }
    }

    private var errorAlert: Alert {
        Alert(
            title: Text(\.alertError),
            message: Text(viewModel.errorMessage),
            dismissButton: .default(Text(\.ok)) { viewModel.isLoading = false }
        )
    }

    private var logoutAlert: Alert {
        Alert(
            title: Text(\.logout),
            message: Text(\.logoutConfirmationTitle),
            primaryButton: .default(Text(\.actionYes)) { userViewModel.logout() },
            secondaryButton: .cancel(Text(\.cancel)) { viewModel.isLoading = false }
        )
    }

    private var loadingOverlay: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text(\.loadingProgress)
            } background: {
                Rectangle().fill(\.groupedSecondary, opacity: \.p0_5)
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UserViewModel())
    }
}
