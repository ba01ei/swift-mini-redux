import Testing
import Foundation
import MiniRedux
import Combine

@Observable class CounterStore: BaseStore<CounterStore.Action> {
  var count = 0

  enum Action {
    case incrementTapped
    case incrementLaterTapped
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .incrementTapped:
      count += 1
      return .none
    case .incrementLaterTapped:
      return .run { send in
        try? await Task.sleep(nanoseconds: 1)
        await send(.incrementTapped)
      }
    }
  }
}

@Test func simpleObservableStore() async throws {
  let store = await CounterStore()
  await store.send(.incrementTapped)
  #expect(await store.count == 1)
  
  await store.send(.incrementLaterTapped)
  await expectWithDelay { await store.count == 2 }
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
