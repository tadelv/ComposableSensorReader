//
//  ReadingsUseCase.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/8/22.
//

import Combine
import ComposableArchitecture
import SensorReaderKit

// MARK: DI for ReadingsUseCase
protocol SensorReadingsProvider {
    associatedtype Reading: SensorReading
    func readings() async throws -> [Reading]
}

extension SensorReader: SensorReadingsProvider {}

// MARK: - UseCase implementation
final class ReadingsUseCase: ReadingProviding {
    private let reader: any SensorReadingsProvider
    private let refreshInterval: Double
    private var readingsSubject = PassthroughSubject<[any Reading], Error>()
    private var subjects: [any Subscription] = []
    private var timer: Timer?

    lazy private(set) var readings: AnyPublisher<[any Reading], Error> = {
        readingsSubject.handleEvents(receiveSubscription: { [unowned self] sub in
            self.subscriptionReceived(sub)
        }, receiveCancel: { [unowned self] in
            self.subscriptionRemoved()
        })
        .eraseToAnyPublisher()
    }()

    init(reader: any SensorReadingsProvider, refreshInterval: Double = 5.0) {
        self.reader = reader
        self.refreshInterval = refreshInterval
    }

    private func subscriptionReceived(_ sub: any Subscription) {
        subjects.append(sub)
        if timer == nil {
            timer = .scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] _ in
                self?.timerFired()
            })
            timerFired()
        }
    }

    private func subscriptionRemoved() {
        _ = subjects.popLast()
        if subjects.isEmpty {
            stopTimer()
        }
    }

    private func timerFired() {
        Task { [weak self] in
            guard let self = self else {
                return
            }
            do {
                let readings = try await self.reader
                    .readings()
                    .map(ReadingImpl.init(from:))
                await MainActor.run {
                    self.readingsSubject.send(readings)
                }
            } catch {
                stopTimer()
                self.subjects = []
                await MainActor.run {
                    self.readingsSubject.send(completion: .failure(error))
                    self.resetPublisher()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetPublisher() {
        readingsSubject = .init()
        readings = readingsSubject.handleEvents(receiveSubscription: { [unowned self] sub in
            self.subscriptionReceived(sub)
        }, receiveCancel: { [unowned self] in
            self.subscriptionRemoved()
        })
        .eraseToAnyPublisher()
    }
}

extension ReadingsUseCase {
    // MARK: Private data struct
    private struct ReadingImpl: Reading {
        var id: String {
            device + name + unit
        }

        var device: String
        var name: String
        var value: String
        var unit: String

        init(from reading: SensorReading) {
            self.device = reading.sensorClass
            self.name = reading.name
            self.value = reading.value
            self.unit = reading.unit
        }
    }
}

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
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        let session = URLSession(configuration: config)
        guard let url = URL(string: "http://192.168.2.159:45678") else {
            fatalError("url could not be constructed")
        }
        return .init {
            try await SensorReader(session, url: url).readings()
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
                            updateTime: Date())
                ]
            }()
        }
    }
}
