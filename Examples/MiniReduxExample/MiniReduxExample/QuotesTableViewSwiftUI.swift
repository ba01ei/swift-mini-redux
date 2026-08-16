import SwiftUI
import UIKit
import MiniRedux

struct QuotesTableViewSwiftUI: View {
  let store: QuotesTableStore

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
