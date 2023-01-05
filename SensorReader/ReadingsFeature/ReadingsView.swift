//
//  ReadingsView.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture
import SwiftUI

struct ReadingsView: View {
    let store: StoreOf<ReadingsFeature>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                List {
                    ForEach(viewStore.state.readings) { reading in
                        ReadingsListCell(reading: reading)
//                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                Button {
//                                    viewModel.toggleFavorite(reading)
//                                } label: {
//                                    VStack {
//                                        Image(systemName: viewModel.isFavorite(reading) ? "star" : "circle")
//                                        Text("Favorite")
//                                    }
//                                }
//
//                            }
                    }
                }
                if viewStore.state.loading {
                    VStack {
                        ProgressView()
                        Text("Loading")
                            .background(Color(UIColor.systemBackground))
                    }
                }
                if let errMessage = viewStore.state.errorMessage {
                    let message = "Failed with: \(errMessage)"
                    Text(message)
                        .background(Color(UIColor.systemBackground))
                }
            }
            .onAppear {
                viewStore.send(.reload)
            }
            .onDisappear {
                viewStore.send(.dismantle)
            }
            .toolbar {
                Button {
                    viewStore.send(.reload)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

            }
            .navigationTitle("List")
        }
    }
}

struct ReadingsView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingsView(store:
                        Store(initialState: ReadingsFeature.State(),
                              reducer: ReadingsFeature())
        )
    }
}
