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

final class AppDI: ObservableObject {
    static let shared = AppDI()

    let persistenceController: PersistenceController
    let bookmarkRepository: any BookmarkRepositoryProtocol
    let userPreferenceRepository: any UserPreferenceRepositoryProtocol
    let bookCatalogCache: BookCatalogCache
    let bookDetailsService: any BookDetailsServing
    let discoverService: any DiscoverServing
    let networkClass: NetworkClass

    init(
        persistenceController: PersistenceController = .shared,
        bookmarkRepository: (any BookmarkRepositoryProtocol)? = nil,
        userPreferenceRepository: (any UserPreferenceRepositoryProtocol)? = nil,
        bookCatalogCache: BookCatalogCache = BookCatalogCache(),
        bookDetailsService: (any BookDetailsServing)? = nil,
        discoverService: (any DiscoverServing)? = nil,
        networkClass: NetworkClass = NetworkClass()
    ) {
        self.persistenceController = persistenceController
        self.bookmarkRepository = bookmarkRepository ?? BookmarkRepositoryImpl(persistenceController: persistenceController)
        self.userPreferenceRepository = userPreferenceRepository ?? UserPreferenceRepositoryImpl(persistenceController: persistenceController)
        self.bookCatalogCache = bookCatalogCache
        self.bookDetailsService = bookDetailsService ?? BookDetailsService()
        self.discoverService = discoverService ?? DiscoverService()
        self.networkClass = networkClass
    }

    // MARK: - Use Cases
    var fetchBookmarksUseCase: any FetchBookmarksUseCaseProtocol {
        FetchBookmarksUseCase(repository: bookmarkRepository)
    }

    var toggleBookmarkUseCase: any ToggleBookmarkUseCaseProtocol {
        ToggleBookmarkUseCase(repository: bookmarkRepository)
    }

    var searchBooksUseCase: any SearchBooksUseCaseProtocol {
        SearchBooksUseCase(repository: BookSearchRepositoryImpl(api: networkClass, cache: bookCatalogCache))
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

    @MainActor
    func makeUserViewModel() -> UserViewModel {
        UserViewModel(persistenceController: persistenceController)
    }

    @MainActor
    func makeBookmarkViewModel() -> BookmarkViewModel {
        BookmarkViewModel(
            fetchBookmarksUseCase: fetchBookmarksUseCase,
            bookmarkRepository: bookmarkRepository,
            persistenceController: persistenceController
        )
    }

    @MainActor
    func makeBookmarkButtonViewModel(book: Book? = nil, imageUrl: URL? = nil) -> BookmarkButtonViewModel {
        let vm = BookmarkButtonViewModel(
            toggleBookmarkUseCase: toggleBookmarkUseCase,
            bookmarkRepository: bookmarkRepository,
            persistenceController: persistenceController
        )
        if let book {
            vm.configure(book: book, imageUrl: imageUrl)
        }
        return vm
    }

    @MainActor
    func makeBookItemViewModel(item: Book) -> BookItemViewModel {
        BookItemViewModel(
            item: item,
            bookmarkRepository: bookmarkRepository,
            persistenceController: persistenceController
        )
    }

    @MainActor
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            searchBooksUseCase: searchBooksUseCase,
            api: networkClass,
            cache: bookCatalogCache
        )
    }

    @MainActor
    func makeDiscoverViewModel() -> DiscoverViewModel {
        DiscoverViewModel(
            fetchDiscoverCategoryUseCase: fetchDiscoverCategoryUseCase,
            service: discoverService
        )
    }

    @MainActor
    func makeBookDetailsViewModel(key: String?) -> BookDetailsViewModel {
        BookDetailsViewModel(
            key: key,
            fetchBookDetailsUseCase: fetchBookDetailsUseCase,
            fetchBookEditionsUseCase: fetchBookEditionsUseCase,
            service: bookDetailsService
        )
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
