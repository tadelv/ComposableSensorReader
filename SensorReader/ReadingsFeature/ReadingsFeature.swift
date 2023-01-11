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

        var searchText = ""
        var searchResults: [ReadingModel] {
            if searchText.isEmpty {
                return readings
            } else {
                return readings.filter {
                    $0.device.lowercased().contains(searchText.lowercased()) ||
                    $0.name.lowercased().contains(searchText.lowercased())
                }
            }
        }
    }

    enum Action: Equatable {
        case readingsFetched([ReadingModel])
        case subscribe
        case errorReceived(String)
        case unsubscribe
        case searchTextChanged(String)
        case reset
        case scheduleLoad
    }

    @Dependency(\.readingsProvider) var readingsProvider
    @Dependency(\.mainQueue) var queue

    private enum ReloadID {}

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .searchTextChanged(let searchString):
            state.searchText = searchString
            return .none
        case .readingsFetched(let newReadings):
            state.loading = false
            state.errorMessage = nil
            state.readings = newReadings
            return .none
        case .subscribe:
            state.connectionCount += 1
            guard state.connectionCount == 1 else {
                return .none
            }
            state.loading = true
            return .task {
                .scheduleLoad
            }
        case .scheduleLoad:
            return .run { send in
                while true {
                    let readings = try await readingsProvider.readings()
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
            state.loading = false
            state.errorMessage = errorMessage
            return .none
        case .unsubscribe:
            state.connectionCount -= 1
            guard state.connectionCount == 0 else {
                return .none
            }
            return .cancel(id: ReloadID.self)
        case .reset:
            state.errorMessage = nil
            return .task {
                .scheduleLoad
            }
        }
    }
}
