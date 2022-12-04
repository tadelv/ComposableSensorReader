//
//  HomeView.swift
//  SensorReader
//
//  Created by Vid Tadel on 12/4/22.
//

import SwiftUI

struct HomeView<Content: View>: View {
    @ViewBuilder private var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        TabView(content: content)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView {
            NavigationView {
                ReadingsList(provider: ReadingsList_Previews.MockProvider())
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Text("All")
            }
            Text("Hello")
                .tabItem {
                    Text("burek")
                }
        }
    }
}