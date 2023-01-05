//
//  FavoritesFeatureTests.swift
//  SensorReaderTests
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture
@testable import SensorReader
import XCTest

@MainActor
final class FavoritesFeatureTests: XCTestCase {
    func testReportsError() async {
        struct TestError: LocalizedError, Equatable {
            var errorDescription: String? {
                "test"
            }
        }
        let store = TestStore(initialState: FavoritesFeature.State(favorites: []),
                              reducer: FavoritesFeature())
        store.dependencies.favoritesApi.load = {

            throw TestError()
        }

        await store.send(.fetch)
        await store.receive(.loaded(.failure(TestError()))) {
            $0.errorMessage = "test"
        }
    }

    func testStoresFavorite() async throws {
        let store = TestStore(initialState: FavoritesFeature.State(favorites: []),
                              reducer: FavoritesFeature())

        await store.send(.add(.init(id: "1")))
        await store.receive(.loaded(.success([.init(id: "1")]))) {
            $0.favorites = [.init(id: "1")]
        }

        let stored = try await store.dependencies.favoritesApi.load()
        XCTAssertEqual(stored, [.init(id: "1")])
    }

    func testRemovesFavorite() async throws {
        let store = TestStore(initialState: FavoritesFeature.State(favorites: [.init(id: "1")]),
                              reducer: FavoritesFeature())
        try await store.dependencies.favoritesApi.save([.init(id: "1")])

        await store.send(.remove(.init(id: "1")))
        await store.receive(.loaded(.success([]))) {
            $0.favorites = []
        }
    }
}
