//
//  ContentView.swift
//  MiniReduxExample
//
//  Created by Bao Lei on 1/19/26.
//

import SwiftUI
import MiniRedux

struct ContentView: View {
  @State var store = ContentStore()
  var body: some View {
    VStack(spacing: 20) {
      if store.loading {
        ProgressView()
      } else {
        Text(store.quote)
      }
      Button("Fetch Random Quote") {
        store.send(.fetchQuoteTapped)
      }
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
