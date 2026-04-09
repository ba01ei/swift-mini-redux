import Testing
import Foundation
import MiniRedux

@Observable class ConcatenateStore: BaseStore<ConcatenateStore.Action> {
  var log: [String] = []

  enum Action {
    case startConcatenate
    case append(String)
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .startConcatenate:
      return .concatenate(
        .run { send in
          try? await Task.sleep(nanoseconds: UInt64(0.05 * 1e9))
          await send(.append("first"))
        },
        .run { send in
          try? await Task.sleep(nanoseconds: UInt64(0.05 * 1e9))
          await send(.append("second"))
        },
        .run { send in
          await send(.append("third"))
        }
      )
    case .append(let value):
      log.append(value)
      return .none
    }
  }
}

@Test func concatenateRunsEffectsSerially() async throws {
  let store = await ConcatenateStore()
  await store.send(.startConcatenate)

  // If effects ran in parallel, "third" (no delay) would arrive before "first" and "second".
  // With concatenation, they must arrive in order.
  await expectWithDelay {
    await store.log == ["first", "second", "third"]
  }
}
