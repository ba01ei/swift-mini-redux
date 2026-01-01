public protocol Reducer {
  associatedtype State: Equatable, Sendable
  associatedtype Action: Sendable
}

public typealias StoreOf<R: Reducer> = Store<R.State, R.Action>
