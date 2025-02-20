import Combine
import SwiftUI

@MainActor public class Store<State, Action>: ObservableObject {
  /// state setter is also public so you can use `$store.state.someProperty` as `Binding`, but otherwise don't manually set the `store.state`, only modify state in a reducer
  @Published public var state: State

  private let reducer: @MainActor (inout State, Action, @escaping @MainActor (Action) -> Void) -> [AnyCancellable]?
  private var cancellables = Set<AnyCancellable>()
  private let debug: Bool

  public init(initialState: State, initialAction: Action? = nil, debug: Bool = false, _ reducer: @escaping @MainActor (inout State, Action, @escaping @MainActor (Action) -> Void) -> [AnyCancellable]?) {
    self.state = initialState
    self.reducer = reducer
    self.debug = debug
    if let initialAction { send(initialAction) }
  }

  public func send(_ action: Action) {
    if debug {
      print("received action \(String(describing: action)))")
    }
    let result = reducer(&state, action, send)
    if debug {
      print("state changes to \(String(describing: state)))")
    }
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

