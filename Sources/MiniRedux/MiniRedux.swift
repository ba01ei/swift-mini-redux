import Combine
import SwiftUI

@MainActor public class Store<State, Action>: ObservableObject {
  /// state setter is also public so you can use `$store.state.someProperty` as `Binding`, but otherwise don't manually set the `store.state`, only modify state in a reducer
  @Published public var state: State

  let reducer: @MainActor (inout State, Action, @escaping @MainActor (Action) -> Void) -> [AnyCancellable]?

  var cancellables = Set<AnyCancellable>()

  public init(_ initialState: State, initialAction: Action? = nil,  _ reducer: @escaping @MainActor (inout State, Action, @escaping @MainActor (Action) -> Void) -> [AnyCancellable]?) {
    self.state = initialState
    self.reducer = reducer
    if let initialAction { send(initialAction) }
  }

  public func send(_ action: Action) {
    // print("received action \(action)")
    let result = reducer(&state, action, send)
    // print("state changes to \(state)")
    for cancellable in result ?? [] {
      cancellable.store(in: &cancellables)
    }
  }
}

/// Allow auto cancellation of Tasks
extension Task {
  public func toCancellable() -> AnyCancellable {
    return AnyCancellable(cancel)
  }
  public func toCancellables() -> [AnyCancellable] {
    return [toCancellable()]
  }
}

