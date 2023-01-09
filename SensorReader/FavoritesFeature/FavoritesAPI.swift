//
//  FavoritesAPI.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture

struct FavoritesStoreAPI {
    var save: ([FavoriteModel]) async throws -> Void
    var load: () async throws -> [FavoriteModel]
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
        var values: [FavoriteModel] = [
            .init(id: "PreviewSensor 1C"),
            .init(id: "PreviewLongNameSensor 2LongName%")
        ]
        return FavoritesStoreAPI { values = $0 } load: { values }
    }

    static var testValue: FavoritesStoreAPI {
        var values: [FavoriteModel] = []
        return FavoritesStoreAPI { values = $0 } load: { values }
    }
}
