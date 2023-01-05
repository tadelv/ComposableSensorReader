//
//  FavoritesUseCase.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/11/22.
//

import Combine

// MARK: UseCase DI
protocol PersistenceProviding {
    associatedtype Content
    func store(_ value: Content?) async throws
    func fetch() async throws -> Content?
}

// MARK: - Implementation
final class FavoritesUseCase<P: PersistenceProviding>: FavoritesProviding where P.Content == [FavoriteModel] {
    private var favoritesSubject: CurrentValueSubject<[FavoriteModel], Error> = .init([])

    lazy var favorites: AnyPublisher<[FavoriteModel], Error> = {
        favoritesSubject
            .handleEvents(receiveSubscription: { [unowned self] _ in
                self.refresh()
            })
            .eraseToAnyPublisher()
    }()

    private let store: P
    private var cancellables: Set<AnyCancellable> = []

    init(store: P) {
        self.store = store
    }

    private func refresh() {
        Task { [weak self, store] in
            do {
                let favorites = try await store.fetch()
                self?.favoritesSubject.send(favorites ?? [])
            } catch {
                self?.favoritesSubject
                    .send(completion: .failure(error))
                self?.resetSubject()
            }
        }
    }

    private func resetSubject() {
        favoritesSubject = CurrentValueSubject([])
        favorites = favoritesSubject
            .handleEvents(receiveSubscription: { [unowned self] _ in
                self.refresh()
            })
            .eraseToAnyPublisher()
    }

    func add(_ favorite: FavoriteModel) async throws {
        let value = favoritesSubject.value + [favorite]
        try await store.store(value)
        favoritesSubject.send(value)
    }

    func remove(_ favorite: FavoriteModel) async throws {
        var value = favoritesSubject.value
        value.removeAll {
            $0 == favorite
        }
        try await store.store(value)
        favoritesSubject.send(value)
    }
}

