//
//  FavoritesAPI.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture

struct FavoritesStoreAPI {
    var save: @Sendable ([FavoriteModel]) async throws -> Void
    var load: @Sendable () async throws -> [FavoriteModel]
}

extension DependencyValues {
    var favoritesApi: FavoritesStoreAPI {
        get { self[FavoritesStoreAPIKey.self] }
        set { self[FavoritesStoreAPIKey.self] = newValue }
    }
}

private enum FavoritesStoreAPIKey: DependencyKey {
    static var liveValue: FavoritesStoreAPI {
        FavoritesStoreAPI { models in
            try await UserDefaultsStore().store(models)
        } load: {
            try await UserDefaultsStore().fetch() ?? []
        }
    }

    static var previewValue: FavoritesStoreAPI {
		let store: LockIsolated<[FavoriteModel]> = .init([
            .init(id: "PreviewSensor 1C"),
            .init(id: "PreviewLongNameSensor 2LongName%")
        ])
        return FavoritesStoreAPI {
			store.setValue($0)
		} load: {
			store.value
		}
    }

    static var testValue: FavoritesStoreAPI {
		let store: LockIsolated<[FavoriteModel]> = .init([])
		return FavoritesStoreAPI {
			store.setValue($0)
		} load: {
			store.value
		}
    }
}
