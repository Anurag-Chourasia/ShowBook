import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct DashboardSearchField: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        HStack {
            Image(\.bookFill)
                .resizable()
                .frame(width: \.p21, height: \.p21)
                .padding([.top, .bottom], \.sixteen)
                .padding([.leading, .trailing], \.p19)
            TextFieldWithDebounce(debouncedText: $viewModel.searchBook)
                .onDisappear { viewModel.cancelRequests() }
                .onChange(of: userViewModel.isLoggedIn) {
                    if !userViewModel.isLoggedIn { viewModel.cancelRequests() }
                }
                .onChange(of: viewModel.searchBook) {
                    viewModel.performSearch()
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignMetric.p26_5)
                .stroke(\.secondary, lineWidth: \.one)
        )
        .padding(.bottom, \.fourteen)
        .padding(.horizontal, \.twenty)
    }
}

struct DashboardSearchStateBanner: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            SurfaceCard {
                StateMessage {
                    Image(viewModel.searchState == .failed ? \.wifiExclamationmark : \.magnifyingglass)
                } title: {
                    titleView.multilineTextAlignment(.center)
                } detail: {
                    detailView
                } actions: {
                    if viewModel.searchState == .failed {
                        Button(\.actionRetry) { viewModel.performSearch() }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(\.twenty)
            .accessibilityIdentifier(.searchStateBanner)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        switch viewModel.searchState {
        case .empty: Text(\.searchNoBooksFound)
        case .failed: Text(\.searchUnableToSearch)
        case .tooShort: Text(\.searchKeepTyping)
        default: Text(\.searchStartSearching)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch viewModel.searchState {
        case .empty: Text(\.searchNoMatches, arguments: [viewModel.searchBook])
        case .failed: Text(\.searchConnectionError)
        default: Text(\.searchMinimumCharacters)
        }
    }
}
