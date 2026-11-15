import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct DashboardBooksListView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: \.zero) {
                BookCollection(books: viewModel.filteredBooks) {
                    viewModel.loadMoreBooksIfNeeded {}
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(\.sixteen)
                } else if !viewModel.loadingMoreBookNotPossible {
                    HStack {
                        Text(\.loadingMore)
                            .padding(\.sixteen)
                            .foregroundColor(\.primary)
                    }
                }
            }
            .padding(.vertical, \.ten)
        }
    }
}
