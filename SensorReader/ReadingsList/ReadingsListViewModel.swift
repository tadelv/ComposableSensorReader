//
//  ReadingsListViewModel.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/8/22.
//

import Combine

@MainActor
class ReadingsListViewModel: ObservableObject {
    @Published var state: ViewModelState = .idle
    @Published var readings: [ReadingModel] = []

    private var providerConnection: AnyCancellable?

    let provider: any ReadingProviding

    init(provider: any ReadingProviding) {
        self.provider = provider
    }

    func load() async {
        state = .loading
        providerConnection = provider.readings.map({ readings in
            readings.map {
                ReadingModel(id: $0.id,
                             device: $0.device,
                             name: $0.name,
                             value: "\($0.value)\($0.unit)")
            }
        })
        .sink(receiveCompletion: { [unowned self] failure in
            if case let .failure(error) = failure {
                state = .error(error)
            }
        }, receiveValue: { [unowned self] models in
            readings = models
            state = .idle
        })
    }
}
