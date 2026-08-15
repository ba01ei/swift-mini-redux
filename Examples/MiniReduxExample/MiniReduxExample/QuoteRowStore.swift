import Foundation
import MiniRedux
import Observation

@Observable
final class QuoteRowStore: BaseStore<QuoteRowStore.Action>, Identifiable {
  let id: UUID
  var text: String
  var isFavorited: Bool

  init(id: UUID = UUID(), text: String, isFavorited: Bool = false) {
    self.id = id
    self.text = text
    self.isFavorited = isFavorited
    super.init()
  }

  enum Action: Sendable {
    case cellTapped
    case textUpdated(String)
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .cellTapped:
      isFavorited.toggle()
      return .none

    case .textUpdated(let text):
      self.text = text
      return .none
    }
  }
}
