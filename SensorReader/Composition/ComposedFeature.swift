//
//  ComposedFeature.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/5/23.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay

struct ComposedFeature: ReducerProtocol {
    struct State: Equatable {
        var favorites = FavoritesFeature.State()
        var readings = ReadingsFeature.State()
        var configSheetVisible = false
        var configUrl: URL?
        var urlValid = false
    }

    enum Action: Equatable {
        case favorites(FavoritesFeature.Action)
        case readings(ReadingsFeature.Action)
        case configVisible(Bool)
        case urlUpdated(String)
        case appLaunch
        case appConfigured(URL)
    }

    @Dependency(\.configurationCall) var configCall
    @Dependency(\.urlStorage) var urlStorage

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.favorites, action: /Action.favorites) {
            FavoritesFeature()
        }
        Scope(state: \.readings, action: /Action.readings) {
            ReadingsFeature()
        }
        Reduce { state, action in
            switch action {
            case .urlUpdated(let urlString):
                guard let url = URL(string: urlString) else {
                    state.urlValid = false
                    return .none
                }
                state.urlValid = true
                state.configUrl = url
                return .fireAndForget {
                    urlStorage.store("server-url", url)
                }
            case .configVisible(let visible):
                state.configSheetVisible = visible
                guard visible == false,
                      let url = state.configUrl else {
                    return .none
                }
                return .task {
                    return .appConfigured(url)
                }
            case .appLaunch:
                return .task {
                    if let url = urlStorage.load("server-url") {
                        return .appConfigured(url)
                    }
                    return .configVisible(true)
                }
            case .appConfigured(let url):
                state.configUrl = url
                configCall(url)
                return .task {
                    .readings(.reset)
                }
            default:
                return .none
            }
        }
    }
}

struct StorageAPI<T: Any> {
    var store: @Sendable (String, T) -> Void
    var load: @Sendable (String) -> T?
}

extension DependencyValues {
    var urlStorage: StorageAPI<URL> {
        get { self[UrlStorageKey.self] }
        set { self[UrlStorageKey.self] = newValue }
    }

    var configurationCall: @Sendable (URL) -> Void {
        get { self[ConfigureCallKey.self] }
        set { self[ConfigureCallKey.self] = newValue }
    }
}

private enum UrlStorageKey: DependencyKey {
    static var liveValue: StorageAPI<URL> {
        StorageAPI { key, value in
            UserDefaults.standard.set(value.absoluteString, forKey: key)
        } load: { key in
            guard let str = UserDefaults.standard.value(forKey: key) as? String else {
                return nil
            }
            return URL(string: str)
        }
    }

    static var previewValue: StorageAPI<URL> {
		let store: LockIsolated<[String: URL]> = .init([:])
        return StorageAPI { [unowned store] key, val in
			store.withValue { value in
				value[key] = val
			}
        } load: { [unowned store] key in
            store.value[key]
        }

    }
}

private enum ConfigureCallKey: DependencyKey {
	static var liveValue: @Sendable (URL) -> Void = unimplemented("ConfigureCallKey")
}
