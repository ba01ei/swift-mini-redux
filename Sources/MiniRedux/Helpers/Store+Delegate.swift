extension Store {
  /// Add a delegate action handler and return the same store
  public func delegate(_ handler: @escaping (@MainActor (Action) -> Void)) -> Self {
    delegatedActionHandler = handler
    return self
  }
}
