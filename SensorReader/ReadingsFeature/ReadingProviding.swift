//
//  ReadingProviding.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/8/22.
//

import ComposableArchitecture
import SensorReaderKit

struct ReadingsAPI {
    var readings: () async throws -> [any SensorReading]
}

extension DependencyValues {
    var readingsProvider: ReadingsAPI {
        get { self[ReadingsProviderKey.self] }
        set { self[ReadingsProviderKey.self] = newValue }
    }
}

private enum ReadingsProviderKey: DependencyKey {
    static var liveValue: ReadingsAPI {
        ReadingsAPI {
            []
        }
    }

    static var previewValue: ReadingsAPI {
        .init {
            {
                struct Reading: SensorReading {
                    var sensorClass: String
                    var name: String
                    var value: String
                    var unit: String
                    var updateTime: Date
                }
                return [
                    Reading(sensorClass: "Preview",
                            name: "Sensor 1",
                            value: "20.0123",
                            unit: "C",
                            updateTime: Date()),
                    Reading(sensorClass: "Preview",
                            name: "Sensor 2",
                            value: "0.15",
                            unit: "%",
                            updateTime: Date()),
                    Reading(sensorClass: "PreviewLongName",
                            name: "Sensor 2LongName",
                            value: "0.15",
                            unit: "%",
                            updateTime: Date())
                ]
            }()
        }
    }
}