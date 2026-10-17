//
//  NetworkClass.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import CommonNetworking
import Combine

// MARK: - NetworkClass
class NetworkClass: ObservableObject {
    private let session: URLSession?
    init(session: URLSession? = nil) { self.session = session }

    // Legacy callbacks remain off-main and have no caller-owned cancellation handle.
    private func fetchData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let transport = AppNetworking.client(session: session)
        Task.detached { [transport] in
            do {
                let response = try await transport.send(URLRequest(url: url))
                completion(response.data, response.response, nil)
            } catch is CancellationError {
                completion(nil, nil, URLError(.cancelled))
            } catch {
                completion(nil, nil, error)
            }
        }
    }

    var fetchBooksCalledCount = 0
    func fetchCountries(completion: @escaping (CountryModel?,Error?) -> Void) {
        guard let url = URL(string: "https://api.first.org/data/v1/countries") else {
            #if DEBUG
            print("Invalid URL")
            #endif
            completion(nil,NSError(domain: "URLCreationError", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid URL"]))
            return
        }
        
        fetchData(from: url) { data, response, error in
            if let error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                #if DEBUG
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                #endif
                completion(nil,NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey : "No data received"]))
                return
            }
            do {
                let decoder = JSONDecoder()
                let jsonResponse = try decoder.decode(CountryModel.self, from: data)
                completion(jsonResponse,nil)
            } catch {
                #if DEBUG
                print("Failed to decode JSON: \(error.localizedDescription)")
                #endif
                completion(nil,error)
            }
        }
        

    }
    
    func fetchIPDetails(completion: @escaping (IPApiResponseModel?, Error?) -> Void) {
        guard let url = URL(string: "http://ip-api.com/json") else {
            completion(nil, NSError(domain: "URLCreationError", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid URL"]))
            return
        }
        
        fetchData(from: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey : "No data received"]))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(IPApiResponseModel.self, from: data)
                completion(response, nil)
            } catch {
                completion(nil, error)
            }
        }
        

    }

    func fetchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) {
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
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        fetchData(from: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
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

