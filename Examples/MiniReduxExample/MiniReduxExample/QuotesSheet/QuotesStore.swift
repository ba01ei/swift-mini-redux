import Foundation
import MiniRedux
import Observation

@Observable
final class QuotesStore: BaseStore<QuotesStore.Action>, Identifiable {
  let id = UUID()
  var isLoading = false
  var tableStore = QuotesTableStore()

  enum Action {
    case addTapped
    case quoteFetched(String)
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .addTapped:
      isLoading = true
      return .run { send in
        guard let url = URL(string: "https://cipher.lei.fyi/quote") else {
          await send(.quoteFetched(""))
          return
        }
        do {
          let response = try await URLSession.shared.data(for: URLRequest(url: url))
          let quote = try JSONDecoder().decode(Quote.self, from: response.0)
          await send(.quoteFetched("\(quote.quote) - \(quote.author)"))
        } catch {
          await send(.quoteFetched("We failed to fetch a quote because \(error). - This App"))
        }
      }

    case .quoteFetched(let quote):
      isLoading = false
      tableStore.send(.quoteAdded(quote))
      return .none
    }
  }
}
