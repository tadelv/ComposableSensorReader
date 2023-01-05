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
    @State private var searchText = ""

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                List {
                    ForEach(viewStore.readings.searchResults) { reading in
                        ReadingsListItem(reading: reading,
                                         store: store.scope(state: \.favorites,
                                                            action: ComposedFeature.Action.favorites))
                    }
                }
                if viewStore.readings.loading {
                    VStack {
                        ProgressView()
                        Text("Loading")
                            .background(Color(UIColor.systemBackground))
                    }
                }
                if let errMessage = viewStore.readings.errorMessage {
                    let message = "Failed with: \(errMessage)"
                    Text(message)
                        .background(Color(UIColor.systemBackground))
                }
            }
            .onAppear {
                viewStore.send(.readings(.reload))
            }
            .onDisappear {
                viewStore.send(.readings(.dismantle))
            }
            .toolbar {
                Button {
                    viewStore.send(.readings(.reload))
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

            }
            .navigationTitle("List")
            .searchable(text: viewStore.binding(get: { state in
                state.readings.searchText
            }, send: { value in
                ComposedFeature.Action.readings(.searchTextChanged(value))
            }))
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
    }
}
