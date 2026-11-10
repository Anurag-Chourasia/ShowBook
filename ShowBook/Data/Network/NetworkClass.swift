//
//  NetworkClass.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import CommonNetworkingKit
import Combine
#if canImport(FoundationKit)
import FoundationKit

private let logger: any AppLogger = UnifiedLogger(subsystem: "com.showbook.app", category: "Network")
#endif

// MARK: - NetworkSemanticError
enum NetworkSemanticError: String, Error, Equatable, Sendable {
    case invalidURL = "showbook.error.invalid_url"
    case noDataReceived = "showbook.error.no_data_received"

    var localizationKey: String { rawValue }
}

// MARK: - NetworkClass
class NetworkClass: ObservableObject {
    private let session: URLSession?
    init(session: URLSession? = nil) { self.session = session }

    // Callbacks remain off-main; consumers own the returned cancellation handle.
    private func fetchData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> Task<Void, Never> {
        let transport = AppNetworking.client(session: session)
        return Task.detached { [transport] in
            do {
                try Task.checkCancellation()
                let response = try await transport.send(URLRequest(url: url))
                try Task.checkCancellation()
                completion(response.data, response.response, nil)
            } catch is CancellationError {
                completion(nil, nil, URLError(.cancelled))
            } catch {
                completion(nil, nil, error)
            }
        }
    }

    var fetchBooksCalledCount = 0
    @discardableResult
    func fetchCountries(completion: @escaping (CountryModel?, Error?) -> Void) -> Task<Void, Never>? {
        guard let url = URL(string: "https://api.first.org/data/v1/countries") else {
            completion(nil, NetworkSemanticError.invalidURL)
            return nil
        }
        
        return fetchData(from: url) { data, _, error in
            if let error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                completion(nil, NetworkSemanticError.noDataReceived)
                return
            }
            do {
                let decoder = JSONDecoder()
                let jsonResponse = try decoder.decode(CountryModel.self, from: data)
                completion(jsonResponse,nil)
            } catch {
                #if DEBUG && canImport(FoundationKit)
                logger.log("Failed to decode JSON: \(error.localizedDescription)", level: .error)
                #endif
                completion(nil,error)
            }
        }
        

    }
    
    @discardableResult
    func fetchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) -> Task<Void, Never>? {
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "fields", value: "key,title,author_name,cover_i,ratings_average,ratings_count")
        ]
        // Form-style query decoders interpret a literal plus as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        fetchBooksCalledCount += 1
        guard let url = components.url else {
            completion(.failure(NetworkSemanticError.invalidURL))
            return nil
        }
        
        return fetchData(from: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkSemanticError.noDataReceived))
                return
            }
            
            do {
                let booksResponse = try JSONDecoder().decode(BooksResponse.self, from: data)
                completion(.success(booksResponse.docs))
            } catch {
                completion(.failure(error))
            }
        }
        

    }
}

