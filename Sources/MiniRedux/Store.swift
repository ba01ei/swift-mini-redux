import Combine
import SwiftUI

@MainActor public class Store<State: Sendable & Equatable, Action: Sendable>: ObservableObject {
  /// state setter is also public so you can use `$store.state.someProperty` as `Binding`, but otherwise don't manually set the `store.state`, only modify state in a reducer
  @Published public var state: State
  nonisolated internal let initialState: State
  private let reducer: @MainActor (inout State, Action, @escaping @MainActor (Action) -> Void) -> Effect<Action>
  private var cancellables = [String: Set<AnyCancellable>]()
  private let debug: Bool
  public var delegatedActionHandler: (@MainActor (Action) -> Void)?

  public init(
    initialState: State, initialAction: Action? = nil,
    delegateActionHandler: (@MainActor (Action) -> Void)? = nil,
    debug: Bool = false, _ reducer: @escaping @MainActor (inout State, Action, @escaping @MainActor (Action) -> Void) -> Effect<Action>) {
      self.state = initialState
      self.reducer = reducer
      self.debug = debug
      self.delegatedActionHandler = delegateActionHandler
      self.initialState = initialState
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
    result.perform(cancellablesDict: &cancellables, send: send)

    delegatedActionHandler?(action)
  }
}
