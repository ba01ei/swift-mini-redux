import Foundation
import MiniRedux
import Testing

@MainActor private final class ContinuationBox {
  var continuation: UnsafeContinuation<Void, Never>?
}

@Test @MainActor func cancelledEffectDropsInFlightAction() async throws {
  struct Feature: Reducer {
    struct State: Equatable {
      var received = false
    }
    enum Action {
      case start
      case cancelSub
      case emitted
    }
    @MainActor static func store(box: ContinuationBox) -> StoreOf<Self> {
      return Store(initialState: State()) { state, action, send in
        switch action {
        case .start:
          return .run(id: "sub") { send in
            await withUnsafeContinuation { continuation in
              Task { @MainActor in
                box.continuation = continuation
              }
            }
            await send(.emitted)
          }
        case .cancelSub:
          return .cancel(id: "sub")
        case .emitted:
          state.received = true
          return .none
        }
      }
    }
  }

  let box = ContinuationBox()
  let store = Feature.store(box: box)
  store.send(.start)
  for _ in 0 ..< 20 where box.continuation == nil {
    try? await Task.sleep(nanoseconds: 50_000_000)
  }
  #expect(box.continuation != nil)

  store.send(.cancelSub)
  box.continuation?.resume()

  try? await Task.sleep(nanoseconds: 100_000_000)
  #expect(store.state.received == false)
}

@Test @MainActor func liveEffectStillDeliversActions() async throws {
  struct Feature: Reducer {
    struct State: Equatable {
      var received = false
    }
    enum Action {
      case start
      case emitted
    }
    @MainActor static func store() -> StoreOf<Self> {
      return Store(initialState: State()) { state, action, send in
        switch action {
        case .start:
          return .run(id: "sub") { send in
            await send(.emitted)
          }
        case .emitted:
          state.received = true
          return .none
        }
      }
    }
  }

  let store = Feature.store()
  store.send(.start)
  for _ in 0 ..< 20 where !store.state.received {
    try? await Task.sleep(nanoseconds: 50_000_000)
  }
  #expect(store.state.received)
}
