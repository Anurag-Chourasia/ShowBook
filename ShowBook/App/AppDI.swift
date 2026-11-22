//
//  AppDI.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 10/11/26.
//

import Foundation
import CoreData
import Combine
import SwiftUI
import UIComponentsKit
import AuthKit
import AuthKitUI
import AuthKitSupabase

final class AppDI: ObservableObject {
    static let shared = AppDI()

    let persistenceController: PersistenceController
    let bookmarkRepository: any BookmarkRepositoryProtocol
    let userPreferenceRepository: any UserPreferenceRepositoryProtocol
    let bookCatalogCache: BookCatalogCache
    let bookDetailsService: any BookDetailsServing
    let discoverService: any DiscoverServing
    let networkClass: NetworkClass
    let imageDataLoader: any ImageDataLoading
    let authBackendFactory: AuthBackendFactory

    init(
        persistenceController: PersistenceController = .shared,
        bookmarkRepository: (any BookmarkRepositoryProtocol)? = nil,
        userPreferenceRepository: (any UserPreferenceRepositoryProtocol)? = nil,
        bookCatalogCache: BookCatalogCache = BookCatalogCache(),
        bookDetailsService: (any BookDetailsServing)? = nil,
        discoverService: (any DiscoverServing)? = nil,
        networkClass: NetworkClass = NetworkClass(),
        imageDataLoader: (any ImageDataLoading)? = nil,
        authBackendFactory: @escaping AuthBackendFactory = SupabaseBackendFactory.make
    ) {
        self.persistenceController = persistenceController
        self.bookmarkRepository = bookmarkRepository ?? BookmarkRepositoryImpl(
            persistenceController: persistenceController
        )
        self.userPreferenceRepository = userPreferenceRepository ?? UserPreferenceRepositoryImpl(
            persistenceController: persistenceController
        )
        self.bookCatalogCache = bookCatalogCache
        self.bookDetailsService = bookDetailsService ?? BookDetailsService()
        self.discoverService = discoverService ?? DiscoverService()
        self.networkClass = networkClass
        self.imageDataLoader = imageDataLoader ?? CommonNetworkingImageDataLoading()
        self.authBackendFactory = authBackendFactory
    }

    // MARK: - Use Cases
    var fetchBookmarksUseCase: any FetchBookmarksUseCaseProtocol {
        FetchBookmarksUseCase(repository: bookmarkRepository)
    }

    var toggleBookmarkUseCase: any ToggleBookmarkUseCaseProtocol {
        ToggleBookmarkUseCase(repository: bookmarkRepository)
    }

    var searchBooksUseCase: any SearchBooksUseCaseProtocol {
        let repo = BookSearchRepositoryImpl(api: networkClass, cache: bookCatalogCache)
        return SearchBooksUseCase(repository: repo)
    }

    var fetchDiscoverCategoryUseCase: any FetchDiscoverCategoryUseCaseProtocol {
        FetchDiscoverCategoryUseCase(repository: discoverService)
    }

    var fetchBookDetailsUseCase: any FetchBookDetailsUseCaseProtocol {
        FetchBookDetailsUseCase(repository: bookDetailsService)
    }

    var fetchBookEditionsUseCase: any FetchBookEditionsUseCaseProtocol {
        FetchBookEditionsUseCase(repository: bookDetailsService)
    }
}

private struct AppDIEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppDI = .shared
}

extension EnvironmentValues {
    var appDI: AppDI {
        get { self[AppDIEnvironmentKey.self] }
        set { self[AppDIEnvironmentKey.self] = newValue }
    }
}
