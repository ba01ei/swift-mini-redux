import Testing
import Foundation
import MiniRedux

@Test func simpleReducer() async throws {
  struct Counter: Reducer {
    struct State: Equatable {
      var count = 0
    }
    enum Action {
      case incrementTapped
      case incrementLaterTapped
    }
    @MainActor static func store() -> StoreOf<Self> {
      return Store(initialState: State()) { state, action, send in
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
