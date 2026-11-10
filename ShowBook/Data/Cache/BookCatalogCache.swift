import Foundation

/// Persistent disk cache for search catalog results in ShowBook.
/// Caches search results atomically to ensure truthful offline catalog behavior.
final class BookCatalogCache {
    static let shared = BookCatalogCache()
    private let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("BookCatalogCache-v1", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    var cachedQueriesCount: Int {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "json" }.count
    }

    var totalSizeBytes: Int {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        var total = 0
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += size
            }
        }
        return total
    }

    var formattedFileSize: String {
        let bytes = totalSizeBytes
        guard bytes > 0 else { return "0 KB" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func cacheKey(for title: String, offset: Int) -> String {
        let clean = title.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-z0-9]", with: "_", options: .regularExpression)
        return "search_\(clean)_\(offset).json"
    }

    func save(books: [Book], for title: String, offset: Int) {
        let file = directory.appendingPathComponent(cacheKey(for: title, offset: offset))
        let response = BooksResponse(docs: books)
        if let data = try? JSONEncoder().encode(response) {
            try? data.write(to: file, options: .atomic)
        }
    }

    func load(for title: String, offset: Int) -> [Book]? {
        let file = directory.appendingPathComponent(cacheKey(for: title, offset: offset))
        guard let data = try? Data(contentsOf: file),
              let response = try? JSONDecoder().decode(BooksResponse.self, from: data) else {
            return nil
        }
        return response.docs
    }

    func clear() {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
