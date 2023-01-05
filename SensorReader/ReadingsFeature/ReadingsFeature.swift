//
//  Readings.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/4/23.
//

import Combine
import ComposableArchitecture
import Foundation


struct ReadingsFeature: ReducerProtocol {

    struct State: Equatable {
        var readings: [ReadingModel] = []
        var loading = false
        var errorMessage: String?
        var connectionCount = 0
    }

    enum Action: Equatable {
        case readingsFetched([ReadingModel])
        case reload
        case errorReceived(String)
        case dismantle
    }

    @Dependency(\.readingsProvider) var readingsProvider
    @Dependency(\.mainQueue) var queue

    private enum ReloadID {}

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .readingsFetched(let newReadings):
            state.loading = false
            state.errorMessage = nil
            state.readings = newReadings
            return .none
        case .reload:
            state.connectionCount += 1
            guard state.connectionCount == 1 else {
                return .none
            }
            state.loading = true
            return .run { send in
                while true {
                    let readings = try await readingsProvider()
                    await send(.readingsFetched(readings.map {
                        ReadingModel(id: $0.sensorClass + $0.name + $0.unit,
                                     device: $0.sensorClass,
                                     name: $0.name,
                                     value: "\($0.value)\($0.unit)"
                        )
                    }))
                    try await queue.sleep(for: 5)
                }
            } catch: { error, send in
                await send(.errorReceived(error.localizedDescription))
            }
            .cancellable(id: ReloadID.self)
        case .errorReceived(let errorMessage):
            state.errorMessage = errorMessage
            return .none
        case .dismantle:
            state.connectionCount -= 1
            guard state.connectionCount == 0 else {
                return .none
            }
            return .cancel(id: ReloadID.self)
        }
    }
}
