//
//  CompositionRoot.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture
import SensorReaderKit
import SwiftUI

struct CompositionRoot {
    let reader: SensorReader
    let favoritesStore = UserDefaultsStore()
    let store: StoreOf<ComposedFeature>

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        let session = URLSession(configuration: config)
        guard let url = URL(string: "http://192.168.2.159:45678") else {
            fatalError("url could not be constructed")
        }
        self.reader = SensorReader(session, url: url)
        let reducer = ComposedFeature()
            .dependency(\.readingsProvider, self.reader.readings)
            .dependency(\.favoritesApi, .init(save: { [favoritesStore] values in
                try await favoritesStore.store(values)
            }, load: { [favoritesStore] in
                try await favoritesStore.fetch() ?? []
            }))
        self.store = StoreOf<ComposedFeature>(initialState: ComposedFeature.State(),
                                              reducer: reducer)
    }

    var composeApp: some View {
        HomeView {
            DashView(store: store)
            .tabItem {
                Image(systemName: "star")
            }
            NavigationView {
                ReadingsView(store: store)
            }.tabItem {
                Image(systemName: "list.bullet")
            }
        }
    }
}
