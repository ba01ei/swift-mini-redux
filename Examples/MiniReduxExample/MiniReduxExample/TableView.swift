import SwiftUI
import UIKit
import MiniRedux

struct TableView: View {
  let store: TableStore

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
      TableViewRepresentable(store: store)
    }
  }
}
