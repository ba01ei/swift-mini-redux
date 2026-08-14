import SwiftUI
import UIKit
import MiniRedux

struct HybridTableView: View {
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
      HybridTableViewRepresentable(store: store)
    }
  }
}
