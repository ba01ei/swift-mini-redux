//
//  Table.swift
//  MiniReduxExample
//
//  Created by Bao Lei on 1/19/26.
//

import MiniRedux
import Observation
import Foundation

@Observable
class TableStore: BaseStore<TableStore.Action>, Identifiable {
  
  // MARK: - State
  let id = UUID()
  var content: [String] = []
  var isLoading = false
  
  // MARK: - Action
  enum Action {
    case addTapped
    case quoteFetched(String)
  }

  // MARK: - Reducer
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
      content.append(quote)
      return .none
    }
  }
}
