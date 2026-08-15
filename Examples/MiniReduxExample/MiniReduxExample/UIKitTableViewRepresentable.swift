import SwiftUI

struct UIKitTableViewRepresentable: UIViewRepresentable {
  let store: QuotesTableStore

  func makeUIView(context: Context) -> UIKitTableView {
    UIKitTableView(store: store)
  }

  func updateUIView(_ uiView: UIKitTableView, context: Context) {}
}
