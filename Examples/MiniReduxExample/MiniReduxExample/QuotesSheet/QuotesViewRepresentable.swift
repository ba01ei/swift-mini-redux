import SwiftUI

struct QuotesViewRepresentable: UIViewRepresentable {
  let store: QuotesStore

  func makeUIView(context: Context) -> QuotesViewUIKit {
    QuotesViewUIKit(store: store)
  }

  func updateUIView(_ uiView: QuotesViewUIKit, context: Context) {}
}
