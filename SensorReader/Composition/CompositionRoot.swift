//
//  CompositionRoot.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture
import SensorReaderKit
import SwiftUI

struct ConfigurationWrapper {
    var configCall: @Sendable (URL) -> Void = { _ in }
}

private class ApiWrapper: @unchecked Sendable {
    var readingsCall: () async throws -> [SensorReading] = {
        struct NotConfigured: LocalizedError {
            var errorDescription: String? {
                "Please set the Server URL first"
            }
        }
        throw NotConfigured()
    }
    lazy var readingsApi = ReadingsAPI { [unowned self] in
        try await readingsCall()
    }
}

struct CompositionRoot {
    let favoritesStore = UserDefaultsStore()
    let store: StoreOf<ComposedFeature>
    private let apiWrapper = ApiWrapper()
    var configurationWrapper = ConfigurationWrapper()

    init() {
        configurationWrapper.configCall = { [apiWrapper] url in
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 5
            config.timeoutIntervalForResource = 5
            let session = URLSession(configuration: config)
            let reader = SensorReader(session, url: url)
            apiWrapper.readingsCall = {
                try await reader.readings()
            }
        }
        let reducer = ComposedFeature()
            .dependency(\.readingsProvider, apiWrapper.readingsApi)
            .dependency(\.favoritesApi, .init(save: { [favoritesStore] values in
                try await favoritesStore.store(values)
            }, load: { [favoritesStore] in
                try await favoritesStore.fetch() ?? []
            }))
            .dependency(\.configurationCall, configurationWrapper.configCall)
        self.store = StoreOf<ComposedFeature>(initialState: ComposedFeature.State(),
                                              reducer: reducer)

    }

	@MainActor
    var composeApp: some View {
        WithViewStore(store) { viewStore in
            HomeView {
                NavigationView {
                    DashView(store: store)
                }
                .tabItem {
                    Image(systemName: "star")
                }
                NavigationView {
                    ReadingsView(store: store)
                }.tabItem {
                    Image(systemName: "list.bullet")
                }
            }
            .onAppear {
                viewStore.send(.appLaunch)
            }
            .sheet(isPresented: viewStore.binding(get: { state in
                state.configSheetVisible
            }, send: { value in
                ComposedFeature.Action.configVisible(value)
            })) {
                SettingsView(store: store)
                    .interactiveDismissDisabled(!viewStore.urlValid)
            }
        }
    }
}
