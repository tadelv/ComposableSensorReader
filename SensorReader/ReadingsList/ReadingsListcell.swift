//
//  ReadingsListcell.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/30/22.
//

import ComposableArchitecture
import SwiftUI

struct ReadingsListCell: View {
    let reading: ReadingModel

    var body: some View {
        EmptyView()
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
