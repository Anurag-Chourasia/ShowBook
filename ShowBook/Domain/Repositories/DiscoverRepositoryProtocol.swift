//
//  DiscoverRepositoryProtocol.swift
//  ShowBook
//

import Foundation

protocol DiscoverRepositoryProtocol: Sendable {
    func loadCategory(_ category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult
}
