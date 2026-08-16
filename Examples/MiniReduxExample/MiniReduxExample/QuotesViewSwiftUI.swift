import SwiftUI
import UIKit
import MiniRedux

struct QuotesViewSwiftUI: View {
  let store: QuotesStore

  var body: some View {
    VStack {
      HStack {
        if store.isLoading {
          ProgressView()
            .padding()
        }
        Spacer()
        Button("Add a quote") {
          store.send(.addTapped)
        }
        .padding()
      }
      List(store.rows) { rowStore in
        QuoteRowViewSwiftUI(store: rowStore)
      }
      .listStyle(.plain)
    }
  }
}
