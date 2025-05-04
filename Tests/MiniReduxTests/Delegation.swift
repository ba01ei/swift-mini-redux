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
    @MainActor static func store(_ initialState: State = State()) -> StoreOf<Self> {
      return Store(initialState: initialState) { state, action, send in
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
      var child: StoreOf<Child>? = nil
    }
    enum Action {
      case showChild(Int)
      case hideChild
      case childActions(Child.Action)
    }
    @MainActor static func store() -> StoreOf<Self> {
      return StoreOf<Self>(initialState: State()) { state, action, send in
        switch action {
        case .showChild(let value):
          if let child = state.child {
            child.send(.valueUpdated(value))
          } else {
            state.child = Child.store(.init(value: value))
            state.child?.delegatedActionHandler = { childAction in
              send(.childActions(childAction))
            }
          }
          return .none
          
        case .hideChild:
          state.child = nil
          return .none

        case .childActions(let childAction):
          switch childAction {
          case .valueUpdated(let value):
            state.value = value
            return .none
          }
        }

      }
    }
  }

  let parentStore = Parent.store()
  #expect(parentStore.state.child == nil)
  
  parentStore.send(.showChild(1))
  #expect(parentStore.state.child?.state.value == 1)
  
  parentStore.state.child?.send(.valueUpdated(100))
  #expect(parentStore.state.value == 100)
  
  parentStore.send(.hideChild)
  #expect(parentStore.state.child == nil)
}
