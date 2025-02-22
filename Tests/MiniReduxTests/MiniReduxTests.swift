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
      case incrementTapped
      case incrementLaterTapped
    }
    @MainActor static func store() -> Store<State, Action> {
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
