//
//  ReadingsFeatureTests.swift
//  SensorReaderTests
//
//  Created by Vid Tadel on 1/4/23.
//

import Combine
import ComposableArchitecture
@testable import SensorReader
import SensorReaderKit
import XCTest

struct MockReading: SensorReading {
    var sensorClass: String
    var name: String
    var value: String
    var unit: String
    var updateTime: Date
}

@MainActor
final class ReadingsFeatureTests: XCTestCase {
    func testErrorReducer() async {
        let store = TestStore(initialState: ReadingsFeature.State(),
                              reducer: ReadingsFeature())

        await store.send(.errorReceived("test")) {
            $0.errorMessage = "test"
        }
    }

    func testReducerSetsData() async {
        let store = TestStore(initialState: ReadingsFeature.State(),
                              reducer: ReadingsFeature())

        await store.send(.readingsFetched([.init(id: "a", device: "a", name: "a", value: "a")])) {
            $0.readings = [
                .init(id: "a", device: "a", name: "a", value: "a")
            ]
        }
    }

    func testReducerReceivesData() async {
        let scheduler = DispatchQueue.test
        var provider: () async throws -> [any SensorReading] = {
            [
                MockReading(sensorClass: "a",
                            name: "a",
                            value: "a",
                            unit: "b",
                            updateTime: Date())
            ]
        }
        let store = TestStore(initialState: ReadingsFeature.State(),
                              reducer: ReadingsFeature()
            .dependency(\.mainQueue, scheduler.eraseToAnyScheduler()))
        store.dependencies.readingsProvider = ReadingsAPI {
            try await provider()
        }

        await store.send(.subscribe) {
            $0.loading = true
            $0.connectionCount = 1
        }
        await store.receive(.scheduleLoad)
        await store.receive(.readingsFetched([.init(id: "aab", device: "a", name: "a", value: "ab")])) {
            $0.loading = false
            $0.readings = [
                .init(id: "aab", device: "a", name: "a", value: "ab")
            ]
        }
//        store.dependencies.readingsProvider = {
        provider = {
            [
                MockReading(sensorClass: "c",
                            name: "a",
                            value: "a",
                            unit: "b",
                            updateTime: Date())
            ]
        }
        await scheduler.advance(by: .seconds(5))
        await store.receive(.readingsFetched([.init(id: "cab", device: "c", name: "a", value: "ab")])) {
            $0.loading = false
            $0.readings = [
                .init(id: "cab", device: "c", name: "a", value: "ab")
            ]
        }
        await store.send(.unsubscribe) {
            $0.connectionCount = 0
        }
    }

    func testReceivesError() async {
        struct E1: LocalizedError {
            var errorDescription: String? {
                "Test"
            }
        }

        let store = TestStore(initialState: ReadingsFeature.State(),
                              reducer: ReadingsFeature())

        store.dependencies.readingsProvider = .init(readings: {
            throw E1()
        })

        await store.send(.subscribe) {
            $0.loading = true
            $0.connectionCount = 1
        }
        await store.receive(.scheduleLoad)
        await store.receive(.errorReceived("Test")) {
            $0.loading = false
            $0.errorMessage = "Test"
        }
    }

    func testReceivesDataAndError() async {
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: ReadingsFeature.State(),
                              reducer: ReadingsFeature()
            .dependency(\.mainQueue, scheduler.eraseToAnyScheduler()))

        var provider: () async throws -> [any SensorReading] = {
            []
        }
        store.dependencies.readingsProvider = ReadingsAPI {
            try await provider()
        }

        await store.send(.subscribe) {
            $0.loading = true
            $0.connectionCount = 1
        }
        await store.receive(.scheduleLoad)
        await store.receive(.readingsFetched([])) {
            $0.loading = false
            $0.readings = []
        }
        struct TestError: LocalizedError {
            var errorDescription: String? {
                "test"
            }
        }
        provider = {
            throw TestError()
        }
        await scheduler.advance(by: .seconds(5))
        await store.receive(.errorReceived("test")) {
            $0.errorMessage = "test"
        }
        provider = {
            XCTFail("should not get called again")
            return []
        }
        await scheduler.advance(by: .seconds(5))
        await store.send(.unsubscribe) {
            $0.connectionCount = 0
        }
    }

    func testAllowsOneOrMoreSubscribers() async {
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: ReadingsFeature.State(),
                              reducer: ReadingsFeature()
            .dependency(\.mainQueue, scheduler.eraseToAnyScheduler()))

        var callCount = 0
        let provider: () async throws -> [any SensorReading] = {
            callCount += 1
            return []
        }
        store.dependencies.readingsProvider = ReadingsAPI {
            try await provider()
        }
        await store.send(.subscribe) {
            $0.loading = true
            $0.connectionCount = 1
        }
        await store.receive(.scheduleLoad)
        await store.receive(.readingsFetched([])) {
            $0.loading = false
            $0.readings = []
        }
        await scheduler.advance(by: .seconds(1))
        await store.send(.subscribe) {
            $0.loading = false
            $0.connectionCount = 2
        }
        await scheduler.advance(by: .seconds(4))
        await store.receive(.readingsFetched([]))
        await scheduler.advance(by: .seconds(4))
        await store.send(.unsubscribe) {
            $0.connectionCount = 1
        }
        await scheduler.advance(by: .seconds(1))
        await store.receive(.readingsFetched([]))

        await store.send(.unsubscribe) {
            $0.connectionCount = 0
        }
        await scheduler.advance(by: .seconds(5))
        XCTAssertEqual(callCount, 3)
    }
}
