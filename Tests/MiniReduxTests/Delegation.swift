//
//  Child.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 5/3/25.
//

import MiniRedux
import Testing

@Test @MainActor func delegation() async throws {
  struct Child: Reducer {
    struct State: Equatable {
      var value = 0
    }
    enum Action: Sendable {
      case valueUpdated(Int)
    }
    @MainActor static func store() -> StoreOf<Self> {
      return Store(initialState: State()) { state, action, send in
        switch action {
        case .valueUpdated(let value):
          state.value = value
          return .none
        }
      }
    }
  }

  struct Parent: Reducer {
    struct State: Equatable {
      var value = 0
    }
    enum Action {
      case childActions(Child.Action)
    }
    @MainActor static func store(childStore: StoreOf<Child>) -> StoreOf<Self> {
      return StoreOf<Self>(initialState: State()) { state, action, send in
        switch action {
        case .childActions(let childAction):
          switch childAction {
          case .valueUpdated(let value):
            state.value = value
            return .none
          }
        }
      }
      .handleActions(from: childStore) { action in
        .childActions(action)
      }
    }
  }

  let childStore = Child.store()
  let parentStore = Parent.store(childStore: childStore)

  childStore.send(.valueUpdated(100))
  #expect(parentStore.state.value == 100)
}
