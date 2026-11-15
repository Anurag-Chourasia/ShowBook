import Foundation

enum BookDetailsError: LocalizedError, Sendable {
    case invalidKey
    case notFound
    case rateLimited
    case serverError(statusCode: Int)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "This book has no valid Open Library identifier. Search for it again to open online details."
        case .notFound:
            return "This book's details are no longer available from Open Library."
        case .rateLimited:
            return "Open Library is busy. Please wait a moment and try again."
        case .serverError:
            return "Open Library was unable to return this book's record. Please try again."
        case .unreadable:
            return "Open Library returned details in an unreadable format."
        }
    }
}
