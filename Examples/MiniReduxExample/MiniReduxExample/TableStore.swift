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
  
  // MARK: - Action
  enum Action {
    case addTapped
  }
  
  // MARK: - Reducer
  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .addTapped:
      return .none

    }
  }
}
