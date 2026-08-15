import Foundation
import MiniRedux
import Observation

@Observable
final class QuoteRowStore: BaseStore<QuoteRowStore.Action>, Identifiable {
  let id: UUID
  var text: String

  init(id: UUID = UUID(), text: String) {
    self.id = id
    self.text = text
    super.init()
  }

  enum Action: Sendable {
    case textUpdated(String)
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .textUpdated(let text):
      self.text = text
      return .none
    }
  }
}
