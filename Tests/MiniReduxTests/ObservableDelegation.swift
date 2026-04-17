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

  init(value: Int = 0) {
    self.value = value
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
        child = ChildStore(value: value)
          .delegateAction(to: self, { childAction in
            .childActions(childAction)
          })
          .forwardParentAction(from: self, { action in
            if case .childActions(let childAction) = action { childAction } else { nil }
          })
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
  #expect(parentStore.child?.reflection == ChildStore(value: 1).reflection)
  
  // Sending a child action to child should update both child and parent (delegate)
  parentStore.child?.send(.valueUpdated(100))
  #expect(parentStore.reflection == {
    let parentStore = ParentStore()
    parentStore.value = 100
    parentStore.child = ChildStore(value: 100)
    
    return parentStore
  }().reflection)

  // Sending a child action to parent should update both parent and child (forward)
  parentStore.send(.childActions(.valueUpdated(123)))
  #expect(parentStore.reflection == {
    let parentStore = ParentStore()
    parentStore.value = 123
    parentStore.child = ChildStore(value: 123)
    return parentStore
  }().reflection)
  
  parentStore.send(.hideChild)
  #expect(parentStore.reflection == {
    let parentStore = ParentStore()
    parentStore.value = 123
    parentStore.child = nil
    return parentStore
  }().reflection)
}
