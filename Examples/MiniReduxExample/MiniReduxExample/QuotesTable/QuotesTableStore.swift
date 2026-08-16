import Foundation
import MiniRedux
import Observation

@Observable
final class QuotesTableStore: BaseStore<QuotesTableStore.Action> {
  var rows: [QuoteRowStore] = []
  @ObservationIgnored var rowsByID: [UUID: QuoteRowStore] = [:]

  enum Action {
    case quoteAdded(String)
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .quoteAdded(let quote):
      let rowStore = QuoteRowStore(text: quote)
      rowsByID[rowStore.id] = rowStore
      rows.append(rowStore)
      return .none
    }
  }
}
