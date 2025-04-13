@preconcurrency import Combine
import Testing
import Foundation
import MiniRedux

@Test func simpleReducer() async throws {
  struct Counter: Reducer {
    struct State {
      var count = 0
    }
    enum Action {
      case incrementTapped
      case incrementLaterTapped
    }
    @MainActor static func store() -> StoreOf<Self> {
      return Store(initialState: State()) { state, action in
        switch action {
        case .incrementTapped:
          state.count += 1
          return .none
        case .incrementLaterTapped:
          return .run { send in
            try? await Task.sleep(nanoseconds: 1)
            await send(.incrementTapped)
          }
        }
      }
    }
  }

  let store = await Counter.store()
  await store.send(.incrementTapped)
  #expect(await store.state.count == 1)
  
  await store.send(.incrementLaterTapped)
  await expectWithDelay { await store.state.count == 2 }
}

@Test @MainActor func delegation() async throws {
  struct Child: Reducer {
    struct State {
      var value = 0
    }
    enum Action: Sendable {
      case valueUpdated(Int)
    }
    @MainActor static func store() -> StoreOf<Self> {
      return Store(initialState: State()) { state, action in
        switch action {
        case .valueUpdated(let value):
          state.value = value
          return .none
        }
      }
    }
  }

  struct Parent: Reducer {
    struct State {
      var value = 0
    }
    enum Action {
      case childActions(Child.Action)
    }
    @MainActor static func store(childStore: StoreOf<Child>) -> StoreOf<Self> {
      return StoreOf<Self>(initialState: State()) { state, action in
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

// MARK: - Helper

func expectWithDelay(timeout: TimeInterval = 1, condition: () async -> Bool) async {
  let interval = 0.1
  for _ in 0 ..< Int(timeout / interval) {
    if await condition() {
      return
    }
    try? await Task.sleep(nanoseconds: UInt64(1e9 * interval))
  }
  Issue.record("condition not met after timeout")
}
