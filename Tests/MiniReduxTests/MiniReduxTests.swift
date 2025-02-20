@preconcurrency import Combine
import Testing
import Foundation
@testable import MiniRedux

@Test func simpleReducer() async throws {
  struct Counter {
    struct State {
      var count = 0
    }
    enum Action {
      case increment
    }
    @MainActor static func store() -> Store<State, Action> {
      return Store(initialState: State()) { state, action, send in
        switch action {
        case .increment:
          state.count += 1
          return nil
        }
      }
    }
  }

  let store = await Counter.store()
  await store.send(.increment)
  #expect(await store.state.count == 1)
}

@Test func backgroundStoreReducer() async throws {
  struct Counter {
    struct State {
      var count = 0
    }
    enum Action {
      case initialized
      case setValue(Int)
    }
    static func store() -> BackgroundStore<State, Action> {
      return BackgroundStore(initialState: State(), initialAction: .initialized) { state, action, send in
        switch action {
        case .initialized:
          Task {
            await send(.setValue(3))
          }
          return nil
        case .setValue(let value):
          state.count = value
          return nil
        }
      }
    }
  }

  let store = Counter.store()
  await confirmation { confirm in
    while true {
      try? await Task.sleep(nanoseconds: 1_000_000)
      if store.state.count == 3 {
        confirm()
        break
      }
    }
  }
  #expect(store.state.count == 3)
}
