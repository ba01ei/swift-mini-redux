/// Being Equatable helps a list of stores to be used as sub-stores
extension Store: Equatable {
  /// Compare stores based on initial state instead of latest state
  /// So that the parent view can avoid unncessary re-renders
  nonisolated public static func == (lhs: Store<State, Action>, rhs: Store<State, Action>) -> Bool {
    return lhs.initialState == rhs.initialState
  }
}

extension Store: Identifiable where State: Identifiable {
  nonisolated public var id: State.ID {
    return initialState.id
  }
}
