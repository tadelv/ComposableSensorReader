//
//  DashView.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import ComposableArchitecture
import SwiftUI

struct DashView: View {
    let store: StoreOf<ComposedFeature>

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        WithViewStore(store) { viewStore in
            let favorites = viewStore.favorites.favorites
            let favoriteReadings = viewStore.readings.readings.filter { reading in
                favorites.contains { favorite in
                    favorite.id == reading.id
                }
            }
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(favoriteReadings) { reading in
                        VStack {
                            Text(reading.value)
                                .lineLimit(1)
                                .font(.title)
                                .minimumScaleFactor(0.2)
                            Text(reading.name)
                                .lineLimit(1)
                                .font(.title2)
                                .minimumScaleFactor(0.2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                        .padding()
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(uiColor: UIColor.secondaryLabel))
                        )
                    }
                }
                .padding()
            }
            .onAppear {
                viewStore.send(.favorites(.fetch))
                viewStore.send(.readings(.subscribe))
            }
            .toolbar {
                Button {
                    viewStore.send(.configVisible(true))
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}

struct DashView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashView(store: Store(initialState: ComposedFeature.State(),
                                  reducer: ComposedFeature()))
        }
    }
}
