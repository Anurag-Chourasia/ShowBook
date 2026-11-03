//
//  PerformanceTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 03/11/26.
//

import XCTest
import CoreData
@testable import ShowBook

final class PerformanceTests: XCTestCase {

    func testBookCatalogCacheThroughput() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = BookCatalogCache(directory: tempDir)

        let books = (0..<100).map { index in
            Book(
                title: "Benchmark Book \(index)",
                ratingsAverage: 4.2,
                ratingsCount: 50,
                authorName: ["Author \(index)"],
                coverI: 1000 + index,
                image: nil
            )
        }

        measure {
            cache.save(books: books, for: "BenchmarkQuery", offset: 0)
            let loaded = cache.load(for: "BenchmarkQuery", offset: 0)
            XCTAssertEqual(loaded?.count, 100)
        }

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testBookmarkBatchPersistenceThroughput() {
        let container = PersistenceController.createInMemoryPersistentContainer()
        let controller = PersistenceController.shared
        controller.container = container

        measure {
            controller.deleteAllBooks()
            for index in 0..<50 {
                let book = Book(
                    title: "Perf Book \(index)",
                    ratingsAverage: 4.5,
                    ratingsCount: 10,
                    authorName: ["Author \(index)"],
                    coverI: index,
                    image: nil
                )
                controller.saveBook(book, imageData: nil)
            }
            let fetched = controller.fetchBooks()
            XCTAssertEqual(fetched.count, 50)
        }
    }

    func testSearchResponseDecodingThroughput() {
        let sampleBook = """
        {"title": "Sample Title", "ratings_average": 4.5, "ratings_count": 100, "author_name": ["Author"], "cover_i": 12345}
        """
        let docs = (0..<200).map { _ in sampleBook }.joined(separator: ",")
        let jsonString = "{\"docs\": [\(docs)]}"
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to encode test JSON")
            return
        }

        let decoder = JSONDecoder()
        measure {
            let response = try? decoder.decode(BooksResponse.self, from: jsonData)
            XCTAssertEqual(response?.docs.count, 200)
        }
    }
}
