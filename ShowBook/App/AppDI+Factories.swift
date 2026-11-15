//
//  AppDI+Factories.swift
//  ShowBook
//

import SwiftUI

extension AppDI {
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
    func makeBookmarkButtonViewModel(
        book: Book? = nil,
        imageUrl: URL? = nil
    ) -> BookmarkButtonViewModel {
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
