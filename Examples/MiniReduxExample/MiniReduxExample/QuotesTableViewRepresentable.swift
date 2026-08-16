import SwiftUI

struct QuotesTableViewRepresentable: UIViewRepresentable {
  let store: QuotesTableStore

  func makeUIView(context: Context) -> QuotesTableViewUIKit {
    QuotesTableViewUIKit(store: store)
  }

  func updateUIView(_ uiView: QuotesTableViewUIKit, context: Context) {}
}
