/// helper to allow a parent store to handle delegated actions from a child store
extension Store {
  
  /// handles actions from a child store
  /// - parameter convertAction converts the child store's action to an action of the current store
  /// - returns the current store
  @MainActor public func handleActions<ChildState, ChildAction: Sendable>(
    from childStore: Store<ChildState, ChildAction>,
    convertAction: @MainActor @escaping (ChildAction) -> Action?
  ) -> Self {
    childStore.delegatedActionHandler = { @MainActor [weak self] childAction in
      if let action = convertAction(childAction) {
        self?.send(action)
      }
    }
    return self
  }
}
