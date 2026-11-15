import SwiftUI
import DesignTokensKit
import LocalizationKit

struct BookRatingView: View {
    let average: Double
    let count: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: \.zero) {
            if !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: \.zero) {
                    ForEach(0..<CatalogMetrics.maximumRating, id: \.self) { index in
                        Image(Double(index) < average.rounded(.down) ? \.starFill : \.star)
                    }
                }
                .font(\.caption)
                .foregroundColor(\.yellow)
                .accessibilityHidden(true)
            }
            let avg = average.formatted(
                .number.precision(.fractionLength(0...2)).locale(LocalizationController.shared.locale)
            )
            let countStr = count.formatted(.number.locale(LocalizationController.shared.locale))
            Text(\.detailsRatings, arguments: [avg, countStr])
                .font(\.caption)
                .foregroundColor(\.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
