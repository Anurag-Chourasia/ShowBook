//
//  NetworkClass.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import Combine

// MARK: - NetworkClass
class NetworkClass: ObservableObject {
    var fetchBooksCalledCount = 0
    func fetchCountries(completion: @escaping (CountryModel?,Error?) -> Void) {
        guard let url = URL(string: "https://api.first.org/data/v1/countries") else {
            print("Invalid URL")
            completion(nil,NSError(domain: "URLCreationError", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil,NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey : "No data received"]))
                return
            }
            do {
                let decoder = JSONDecoder()
                let jsonResponse = try decoder.decode(CountryModel.self, from: data)
                completion(jsonResponse,nil)
            } catch {
                print("Failed to decode JSON: \(error.localizedDescription)")
                completion(nil,error)
            }
        }
        
        task.resume()
    }
    
    func fetchIPDetails(completion: @escaping (IPApiResponseModel?, Error?) -> Void) {
        guard let url = URL(string: "http://ip-api.com/json") else {
            completion(nil, NSError(domain: "URLCreationError", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
        
        task.resume()
    }

    func fetchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) {
        let baseURL = "https://openlibrary.org/search.json"
        let limit = 10
        let urlString = "\(baseURL)?title=\(title)&limit=\(limit)&offset=\(offset)"
        fetchBooksCalledCount += 1
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("fetchBooksCalledCount",self.fetchBooksCalledCount)
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("fetchBooksCalledCount",self.fetchBooksCalledCount)
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                
                let booksResponse = try JSONDecoder().decode(BooksResponse.self, from: data)
                print("fetchBooksCalledCountSuccess",self.fetchBooksCalledCount)
                completion(.success(booksResponse.docs))
            } catch {
                print("fetchBooksCalledCount",self.fetchBooksCalledCount)
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

