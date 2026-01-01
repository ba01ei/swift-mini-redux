# Mini Redux Architecture

A minimal implementation of the Redux pattern in Swift.

Inspired by TCA, i.e. [The Composable Architecture by PointFree](https://github.com/pointfreeco/swift-composable-architecture).

Starting December 2025, this library is backed by [Swift Observable](https://developer.apple.com/documentation/Observation/Observable)

## Basic example

 ```swift
import MiniRedux
import SwiftUI

@Observable class AStore: BaseStore<AStore.Action> {
  // MARK: - State
  var text = ""
  var number = 1

  // MARK: - Action
  enum Action {
    case action1
    case action2
  }

  // MARK: - Reducer
  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .action1:
      store.text = "..."
      return .none

    case .action2:
      return .run { send in
        let result = await someAsyncFunction(...)
        await send(anotherAction)
      }
    }
  }
}

struct AView: View {
  let store: AStore
  var body: some View {
    Text(store.text) // this will be automatically observing
    Button("...") { store.send(action1) }
  }
}
```

The idea is that instead of letting the view be driven by a view model with completely freeform logic, we adhere to a consistent pattern where:

1. Every changeable thing displayed in the view is based on the state of the store (e.g. `store.text`)
2. Every change of state is from an action sent to the store (e.g. on button tap we call `store.send(Action.buttonTapped)`)
3. Every asynchronous operation is carried out through an Effect returned by an action

This pattern provides a few benefits:

1. It's very easy to debug what is changing the state (e.g. put a `print("... \(action)")` in reduce function)
2. It's very easy to unit test (each action represents what a user can do. Call store.send and check if the state updates accordingly)
3. Async operations and subscriptions to data sources are easier to follow, and adhere to Swift Concurrency
4. Cancellations of async operations and subscriptions are automatically managed

## How to handle interactions between a parent view and a child view

A store can contain a child store.

Every store has a delegate where actions will also be sent. The parent store can initialize the child store by passing a delegate action handler closure where a parent action is sent based on the child action.

See example in [this unit test](Tests/MiniReduxTests/ObervableDelegate.swift)

## How to handle a list view with each item having its own store

See example in [this unit test](Tests/MiniReduxTests/ObervableList.swift)


## Comparison to TCA

TCA is a much more fully fledged framework, where as MiniRedux is a minimalist implementation. MiniRedux is a student of TCA. 

They are based on the same philosophy, there are different trade-offs.

TCA store's state is based on a struct. MiniRedux's store's state is just a set of properties on store class. The benefit of the TCA approach is that the struct based state gets automatic equatable implementation, and ability to print a description. MiniRedux skips the state struct declaration so it can directly reuse the Swift @Observation macro to track changes (TCA achieved so through its own implementation of @ObervableState macro). To partially makeup for the equatability and debuggability, MiniRedux store provides a `reflection` property that can be used in test or debugging to compare state changes.

TCA has a layer called reducer, which is its own struct. There is no need to subclass the store. It is closer to functional programming and better embodies the "composition over inheritance" principle. MiniRedux requires each store to inherit BaseStore. On the flip side, the minor benefits are: slightly less boilerplate and one less type to maintain (there is no reducer, just a reduce function that the store needs to override).

TCA uses a mechanism called scoping to manage interactions between parent and children stores (i.e. a child store is scoped from a subset of the parent's state'). This allows the entired tree of states from parent to each children to be representated in one struct value. With MiniRedux, children stores are directly owned by parent stores. You are still get the full state through `relection` property (but less elegant as TCA), on the flip side it's a much simpler implementation (less code and less change for a bug or performance overhead).

TCA currently has much better testing infrastructure, with TestStore. MiniRedux in principle is very testable but for now provides less testing helpers. Though this can be improved in the future.

## Pre-Observation Implementation

There is an earlier implementation of this library that doesn't depend on Observable Macro and can be used below iOS 17.

The state is based on a struct, more similar to TCA.

### Basic example

The simplest counter app

```swift
import MiniRedux
import SwiftUI

struct Counter: Reducer {
  struct State: Equatable {
    var count = 0
  }
  enum Action {
    case incrementTapped
    case decrementTapped
  }
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State()) { state, action, send in
      switch action {
      case .incrementTapped:
        state.count += 1
        return .none
      case .decrementTapped:
        state.count -= 1
        return .none
      }
    }
  }
}

struct CounterView: View {
  @ObservedObject private var store = Counter.store()

  var body: some View {
    VStack {
      Text("\(store.state.count)")
      Button("+") {
        store.send(.incrementTapped)
      }
      Button("-") {
        store.send(.decrementTapped)
      }
    }
  }
}
```

### Async side effect

Return a Task in the reducer function to run asynchronously, and call `send()` when the result is ready to trigger another action to update the state.

```swift
struct RandomQuote: Reducer {
  struct State: Equatable {
    var text = ""
  }
  enum Action {
    case getQuoteTapped
    case quoteLoaded(String)
  }
  struct Response: Codable {
    let quote: String
    let author: String
  }
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State()) { state, action, send in
      switch action {
      case .getQuoteTapped:
        state.text = "Loading..."
        return run { send in
          guard let url = URL(string: "https://cipher.lei.fyi/quote") else { return }
          do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let result = try JSONDecoder().decode(Response.self, from: data)
            send(.quoteLoaded(result.quote + " - " + result.author))
          } catch {
            send(.quoteLoaded("Error: \(error)"))
          }
        }
        .cancellable(id: "load", cancelInFlight: true)
      case .quoteLoaded(let text):
        state.text = text
        return .none
      }
   }
 }
}

struct RandomQuoteView: View {
  @ObservedObject private var store = RandomQuote.store()

  var body: some View {
    VStack {
      Text(store.state.text)
      Button("Get Random Quote") {
        store.send(.getQuoteTapped)
      }
    }
  }
}
```

You can also return an effect based on a Combine publisher.

```swift
@MainActor static func store() -> Store<State, Action> {
  // when creating a store, an initialAction can be passed so it will be called when the store is initialized
  return Store(initialState: State(), initialAction: .initialized) { state, action, _ in
    switch action {
    case .initialized:
      return .publisher {
        map { result in
          .resultPublished(result)
        }
      }
    case .resultPublished(let result):
      ...  
    }
  }
}
```

### Interactions between two stores 

This example shows how a parent store can communicate with a child store in both directions.

If a parent store's state have a child store property, and the changes to the internal value of the child store won't trigger the state update of the parent store. This is because the `Equatable` comparison result of stores only depend on their initial states. Because of this, by creating child stores and child views, we can avoid unnecessary re-renders of the views.

Although this is not as magical as `@Observable` or TCA's `@ObservableState` which automatically tracks which state properties is observed by each view, it still gets the job done in most cases, and the benefit is a much simpler library and arguably lower risk.

```swift

struct Parent: Reducer {
  struct State: Equatable {
    var value = 0
    /// If the child store makes changes to the child state, parent store's state won't trigger updates in the parent view
    var child: StoreOf<Child>? = nil
  }
  enum Action {
    case showChild(Int)
    case hideChild
    case childActions(Child.Action)
  }
  @MainActor static func store() -> StoreOf<Self> {
    return StoreOf<Self>(initialState: State()) { state, action, send in
      switch action {
      case .showChild(let value):
        if let child = state.child {
          child.send(.valueUpdated(value))
        } else {
          state.child = Child.store(.init(value: value))
          state.child?.delegatedActionHandler = { childAction in
            send(.childActions(childAction))
          }
        }
        return .none
        
      case .hideChild:
        state.child = nil
        return .none

      case .childActions(let childAction):
        switch childAction {
        case .valueUpdated(let value):
          state.value = value
          return .none
        }
      }

    }
  }
}

struct Child: Reducer {
  struct State: Equatable {
    var value = 0
  }
  enum Action: Sendable {
    case valueUpdated(Int)
  }
  @MainActor static func store(_ initialState: State = State()) -> StoreOf<Self> {
    return Store(initialState: initialState) { state, action, send in
      switch action {
      case .valueUpdated(let value):
        state.value = value
        return .none
      }
    }
  }
}
```

### A list of child stores

Compared to TCA, this library doesn't offer `.scope()`.

But we can still main the relationship between parent and children stores even when there is a list of dynamically updating children, as illustrated in this example.

Here is a [diff view](https://www.diffchecker.com/8s9ip7My/) between TCA vs Swift Mini Redux. TCA makes it slightly simpler through `.scope()` but the difference is small.

```swift
struct List: Reducer {
  struct State: Equatable {
    var items: [StoreOf<Item>] = []
    var lastTapped: String? = nil
  }
  
  enum Action {
    case itemsFetched([Item.State])
    case itemAction(id: String, Item.Action)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State()) { state, action, send in
      switch action {

      case .itemsFetched(let items):
        state.items.updateInPlace(newItems: items) { _, item in
          return Item.store(item).delegate { childAction in
            send(.itemAction(id: item.id, childAction))
          }
        }
        return .none
        
      case .itemAction(id: let id, let action):
        switch action {
        case .tapped:
          state.lastTapped = id
          return .none

        default:
          return .none

        }
      }
    }
  }
}

struct Item: Reducer {
  struct State: Equatable, Identifiable {
    let id: String
    var text: String? = nil
  }
  
  enum Action {
    case initialized
    case contentFetched(String)
    case tapped
  }
  
  @MainActor static func store(_ initialState: State) -> StoreOf<Self> {
    return Store(initialState: initialState, initialAction: .initialized) { state, action, send in
      switch action {
      case .initialized:
        return .run { [id = state.id] send in
          await send(.contentFetched("Content of \(id) fetched at \(Date())"))
        }
        
      case .contentFetched(let content):
        state.text = content
        return .none
        
      case .tapped:
        return .none

      }
    }
  }
}
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
