import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

struct BookItemDetailsView: View {
    let item: Book
    let showsRatings: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: \.eight) {
            Text(item.title)
                .font(\.headline)
                .foregroundColor(\.primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : CatalogMetrics.listTitleLines)
            Text(item.authorName?.joined(separator: ", ") ?? String(\.detailsNoAuthor))
                .font(\.footnote)
                .foregroundColor(\.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : CatalogMetrics.listTitleLines)
            if showsRatings && AppRuntime.ratingsEnabled, let rating = item.availableRating {
                BookRatingView(average: rating.average, count: rating.count)
            } else if showsRatings && AppRuntime.ratingsEnabled {
                Text(\.notRated).font(\.caption).foregroundColor(\.secondary)
            }
        }
    }
}
