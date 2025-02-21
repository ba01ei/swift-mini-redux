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
