//
//  ComposedFeature.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture

struct ComposedFeature: ReducerProtocol {
    struct State: Equatable {
        var favorites = FavoritesFeature.State()
        var readings = ReadingsFeature.State()
    }

    enum Action: Equatable {
        case favorites(FavoritesFeature.Action)
        case readings(ReadingsFeature.Action)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.favorites, action: /Action.favorites) {
            FavoritesFeature()
        }
        Scope(state: \.readings, action: /Action.readings) {
            ReadingsFeature()
        }
    }
}
