//
//  Child.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 5/3/25.
//

import MiniRedux
import Testing
import Observation
import Combine

@Observable class ChildStore: BaseStore<ChildStore.Action> {
  
  var value = 0

  init(value: Int = 0, delegatedActionHandler: ((Action) -> Void)?) {
    self.value = value
    super.init(delegatedActionHandler: delegatedActionHandler)
  }

  enum Action: Sendable {
    case valueUpdated(Int)
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .valueUpdated(let value):
      self.value = value
      return .none
    }
  }
}

@Observable class ParentStore: BaseStore<ParentStore.Action> {
  
  var value = 0
  var child: ChildStore? = nil

  enum Action {
    case showChild(Int)
    case hideChild
    case childActions(ChildStore.Action)
  }
  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .showChild(let value):
      if let child {
        child.send(.valueUpdated(value))
      } else {
        child = ChildStore(value: value) { [weak self] childAction in
          self?.send(.childActions(childAction))
        }
      }
      return .none
      
    case .hideChild:
      child = nil
      return .none
      
    case .childActions(let childAction):
      switch childAction {
      case .valueUpdated(let value):
        self.value = value
        return .none
      }
    }
  }
}


@Test @MainActor func obervableDelegation() async throws {
  
  let parentStore = ParentStore()
  #expect(parentStore.child == nil)
  
  parentStore.send(.showChild(1))
  #expect(parentStore.child?.value == 1)
  
  parentStore.child?.send(.valueUpdated(100))
  #expect(parentStore.value == 100)
  
  parentStore.send(.hideChild)
  #expect(parentStore.child == nil)
}
