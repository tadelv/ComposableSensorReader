//
//  SensorReaderApp.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/4/22.
//

import SwiftUI
import SensorReaderKit

@main
struct SensorReaderApp: App {
    var isUnitTesting: Bool {
        return ProcessInfo.processInfo.environment["UNITTEST"] == "1"
    }

    let compositionRoot = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            if isUnitTesting {
                EmptyView()
            } else {
                compositionRoot.composeApp
            }
        }
    }
}
