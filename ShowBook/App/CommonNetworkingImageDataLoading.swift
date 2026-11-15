//
//  CommonNetworkingImageDataLoading.swift
//  ShowBook
//

import Foundation
import CommonNetworkingKit
import UIComponentsKit

struct CommonNetworkingImageDataLoading: ImageDataLoading {
    private let fetcher: any ImageDataFetching

    init(fetcher: (any ImageDataFetching)? = nil) {
        self.fetcher = fetcher ?? ImageDataFetcher(client: AppNetworking.client())
    }

    func loadImageData(from url: URL) async throws -> Data {
        try await fetcher.fetchData(for: url)
    }
}
