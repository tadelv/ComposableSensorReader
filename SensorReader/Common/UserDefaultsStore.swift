//
//  UserDefaultsStore.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/29/22.
//

import Foundation

protocol PersistenceProviding {
    associatedtype Content
    func store(_ value: Content?) async throws
    func fetch() async throws -> Content?
}

struct UserDefaultsStore: PersistenceProviding {
    typealias Content = [FavoriteModel]
    private static let contentKey = "sensorReader.persistence"
    func store(_ value: Content?) async throws {
        let values = value?.map { $0.id } ?? []
        UserDefaults.standard.setValue(values, forKey: Self.contentKey)
    }

    func fetch() async throws -> Content? {
        guard let values = UserDefaults.standard.value(forKey: Self.contentKey) as? [String] else {
            return nil
        }
        return values.map(FavoriteModel.init(id:))
    }
}
