//
//  SettingsView.swift
//  SensorReader
//
//  Created by Vid Tadel on 1/6/23.
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<ComposedFeature>

    struct ViewState: Equatable {
        var configUrl: URL?
        var urlValid = false

        init(state: ComposedFeature.State) {
            self.configUrl = state.configUrl
            self.urlValid = state.urlValid
        }
    }
    var body: some View {
        WithViewStore(store, observe: ViewState.init(state:)) { viewStore in
            Form {
                Section("Server url") {
                    TextField("Set url", text: viewStore.binding(get: { state in
                        state.configUrl?.absoluteString ?? ""
                    }, send: { value in
                        ComposedFeature.Action.urlUpdated(value)
                    }))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }
                Button("Done") {
                    viewStore.send(.configVisible(false))
                }
                .frame(maxWidth: .infinity)
                .disabled(viewStore.state.urlValid == false)
            }

        }

    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            store: Store(initialState: ComposedFeature.State(),
                         reducer: ComposedFeature())
        )
    }
}
