public protocol Reducer {
    associatedtype State
    associatedtype Action
}

public typealias StoreOf<R: Reducer> = Store<R.State, R.Action>
