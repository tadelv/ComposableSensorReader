//
//  ReadingModel.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/9/22.
//

import Foundation

struct ReadingModel: Identifiable, Equatable {
    let id: String
    let device: String
    let name: String
    let value: String

    init(id: String, device: String, name: String, value: String) {
        self.id = id
        self.device = device
        self.name = name
        self.value = value.truncated()
    }
}

extension String {
    func truncated() -> String {
        let scanner = Scanner(string: self)
        guard let doubleVal = scanner.scanDouble() else {
            return self
        }
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 2
        let value = formatter.string(from: .init(value: doubleVal)) ?? "\(doubleVal)"
        let unit = (scanner.scanCharacters(from: .whitespacesAndNewlines.inverted) ?? "")
        return value + unit
    }
}
