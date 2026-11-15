import Foundation

struct Book: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let ratingsAverage: Double?
    let ratingsCount: Int?
    let authorName: [String]?
    let coverI: Int?
    let image: Data?
    var key: String? = nil

    // Missing ratings and legacy bookmark zero defaults are not real scores.
    var availableRating: (average: Double, count: Int)? {
        guard let average = ratingsAverage, average.isFinite, (0...5).contains(average),
              let count = ratingsCount, count > 0 else { return nil }
        return (average, count)
    }

    enum CodingKeys: String, CodingKey {
        case title, key
        case ratingsAverage = "ratings_average"
        case ratingsCount = "ratings_count"
        case authorName = "author_name"
        case coverI = "cover_i"
        case image
    }

    // Implementing Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.ratingsAverage == rhs.ratingsAverage &&
        lhs.ratingsCount == rhs.ratingsCount &&
        lhs.authorName == rhs.authorName &&
        lhs.coverI == rhs.coverI &&
        lhs.image == rhs.image
    }
}

// MARK: - BooksResponse
struct BooksResponse: Codable {
    let docs: [Book]
}
