//
//  ReadingsListcell.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/30/22.
//

import SwiftUI

struct ReadingsListCell: View {
    let reading: ReadingModel

    var body: some View {
        HStack {
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
