//
//  ContentStore.swift
//  MiniReduxExample
//
//  Created by Bao Lei on 1/19/26.
//

import MiniRedux
import Observation
import Foundation

@Observable
class ContentStore: BaseStore<ContentStore.Action> {
  
  // MARK: - State
  var loading = false
  var quote = ""
  var swiftUITablePresented = false
  var uiKitTablePresented = false
  @ObservationIgnored lazy var tableStore = QuotesTableStore().delegateAction(to: self, { tableAction in
      .table(tableAction)
  })

  // MARK: - Action
  enum Action {
    case fetchQuoteTapped
    case quoteFetched(String)
    case showTableTapped
    case showUIKitTableTapped
    
    // child action
    case table(QuotesTableStore.Action)
  }
  
  // MARK: - Reducer
  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .fetchQuoteTapped:
      loading = true
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
      loading = false
      self.quote = quote
      return .none

    case .showTableTapped:
      swiftUITablePresented = true
      return .none

    case .showUIKitTableTapped:
      uiKitTablePresented = true
      return .none

    case .table(let tableAction):
      switch tableAction {
      case .quoteFetched(let quote):
        self.quote = quote
      default:
        break
      }
      return .none
    }
  }
}
