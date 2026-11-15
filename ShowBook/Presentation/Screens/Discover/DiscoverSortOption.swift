import Foundation
import LocalizationKit

enum DiscoverSortOption: String, CaseIterable, Identifiable {
    case title = "Title"
    case average = "Average"
    case hits = "Hits"

    var id: String { rawValue }

    var titleKeyPath: KeyPath<ShowBookStrings, String> {
        switch self {
        case .title: return \.discoverSortTitle
        case .average: return \.discoverSortAverage
        case .hits: return \.discoverSortHits
        }
    }

    func sort(_ books: [Book]) -> [Book] {
        switch self {
        case .title: return books.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .average: return books.sorted { ($0.availableRating?.average ?? -1) > ($1.availableRating?.average ?? -1) }
        case .hits: return books.sorted { ($0.ratingsCount ?? -1) > ($1.ratingsCount ?? -1) }
        }
    }
}

extension DiscoverCategory {
    var titleKeyPath: KeyPath<ShowBookStrings, String> {
        switch self {
        case .fiction: return \.categoryFiction
        case .mystery: return \.categoryMystery
        case .science: return \.categoryScience
        case .history: return \.categoryHistory
        }
    }
}
