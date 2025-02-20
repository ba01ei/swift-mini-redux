@preconcurrency import Combine

/// Similar to Store, but state is updated on a background thread.
public actor BackgroundStore<State: Sendable, Action: Sendable> {
  nonisolated private let subject: CurrentValueSubject<State, Never>
  private let reducer:
    @Sendable (inout State, Action, @escaping @Sendable (Action) async -> Void) -> [AnyCancellable]?
  private var cancellables = Set<AnyCancellable>()
  private let debug: Bool

  public init(
    initialState: State,
    initialAction: Action? = nil,
    debug: Bool = false,
    _ reducer: @escaping @Sendable (inout State, Action, @escaping @Sendable (Action) async -> Void)
      -> [AnyCancellable]?
  ) {
    self.subject = CurrentValueSubject(initialState)
    self.reducer = reducer
    self.debug = debug

    if let initialAction {
      Task {
        await send(initialAction)
      }
    }
  }

  nonisolated public var state: State {
    return subject.value
  }

  nonisolated public var publisher: AnyPublisher<State, Never> {
    return subject.eraseToAnyPublisher()
  }

  public func send(_ action: Action) async {
    if debug {
      print("store received action \(String(describing: action))")
    }
    var state = subject.value
    let result = reducer(&state, action, { [weak self] action in
      await self?.send(action)
    })
    subject.send(state)
    if debug {
      print("state changes to \(String(describing: state))")
    }
    for cancellable in result ?? [] {
      cancellable.store(in: &cancellables)
    }
  }
}

