//
//  FavoritesFeature.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture

struct FavoriteModel: Equatable {
    let id: String
}

struct FavoritesFeature: ReducerProtocol {
    struct State: Equatable {
        var favorites: [FavoriteModel] = []
        var errorMessage: String?
    }

    enum Action: Equatable {
        case fetch
        case loaded(TaskResult<[FavoriteModel]>)
        case add(FavoriteModel)
        case remove(FavoriteModel)
    }

    @Dependency(\.favoritesApi) var favoritesApi

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .fetch:
            return .task {
                await .loaded(TaskResult { try await favoritesApi.load() })
            }
        case .add(let favorite):
            let newValues = state.favorites + [favorite]
            return .task {
                await .loaded(
                    TaskResult {
                        try await favoritesApi.save(newValues)
                        return newValues
                    }
                )
            }
        case .remove(let favorite):
            var copy = state.favorites
            copy.removeAll { $0 == favorite }
            return .task { [copy] in
                await .loaded(
                    TaskResult {
                        try await favoritesApi.save(copy)
                        return copy
                    }
                )
            }
        case .loaded(let result):
            switch result {
            case .success(let favorites):
                state.errorMessage = nil
                state.favorites = favorites
            case .failure(let error):
                state.errorMessage = error.localizedDescription
            }
            return .none
        }
    }
}
