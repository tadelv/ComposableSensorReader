//
//  ReadingsView.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture
import SwiftUI

struct ReadingsView: View {
    let store: StoreOf<ComposedFeature>

    var body: some View {
        WithViewStore(store, observe: {
            $0.readings
        }) { viewStore in
            ZStack {
                List {
                    ForEach(viewStore.searchResults) { reading in
                        ReadingsListItem(reading: reading,
                                         store: store.scope(state: \.favorites,
                                                            action: ComposedFeature.Action.favorites))
                    }
                }
                if viewStore.loading {
                    VStack {
                        ProgressView()
                        Text("Loading")
                            .background(Color(UIColor.systemBackground))
                    }
                }
                IfLetStore(store.scope(state: \.readings.errorMessage)) {
                    WithViewStore($0) { viewStore in
                        Text("Failed with: " + viewStore.state)
                    }
                }
            }
            .onAppear {
                viewStore.send(.readings(.subscribe))
            }
            .onDisappear {
                viewStore.send(.readings(.unsubscribe))
            }
            .toolbar {
                Button {
                    viewStore.send(.readings(.reset))
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

            }
            .navigationTitle("List")
            .searchable(text: viewStore.binding(get: \.searchText,
                                                send: {
                ComposedFeature.Action.readings(.searchTextChanged($0))
            }))
        }
    }
}

struct ReadingsListItem: View {
    let reading: ReadingModel
    let store: StoreOf<FavoritesFeature>

    var body: some View {
        WithViewStore(store) { viewStore in
            let isFavorite = viewStore.favorites.contains {
                $0.id == reading.id
            }
            HStack {
                Button {
                    switch isFavorite {
                    case true:
                        viewStore.send(.remove(.init(id: reading.id)))
                    case false:
                        viewStore.send(.add(.init(id: reading.id)))
                    }
                } label: {
                    Image(systemName: "star.fill")
                        .foregroundColor(isFavorite ? .blue : .gray)
                }
                VStack(alignment: .leading) {
                    Text(reading.name)
                    Text(reading.device).font(.caption)
                }
                Spacer()
                Text(reading.value)
                    .font(.callout)
            }
            .padding([.top, .bottom])

        }
    }
}

struct ReadingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReadingsView(store:
                            Store(initialState: ComposedFeature.State(),
                                  reducer: ComposedFeature())
            )
        }
        NavigationView {
            ReadingsView(store:
                            Store(initialState: ComposedFeature.State(),
                                  reducer: ComposedFeature()
                                .dependency(\.readingsProvider, .init(readings: {
                                    struct E1: Error {}
                                    throw E1()
                                })))
            )
        }
    }
}
