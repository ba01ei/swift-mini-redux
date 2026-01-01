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
    Text(store.text) // observed automatically
    Button("...") { store.send(.action1) }
  }
}
```

Rather than freeform logic in view models, we adhere to a pattern where:

1. Every visible element is driven by the store's state (e.g., `store.text`).
2. Every state change is triggered by an action sent to the store (e.g., `store.send(.buttonTapped)`).
3. Every asynchronous operation is managed through an `Effect` returned by `reduce`.

Benefits:

1. **Easy Debugging**: Track state changes by printing the `action` in `reduce`.
2. **Testable**: Each action represents a user interaction. Call `send` and assert state updates.
3. **Structured Concurrency**: Async operations and data subscriptions follow Swift Concurrency.
4. **Auto-Management**: Cancellations of async tasks are handled automatically.

## How to handle interactions between a parent view and a child view

A store can contain child stores. Each store has a delegate for action forwarding. The parent initializes a child store, providing a closure to map child actions back to parent actions.

See example in [this unit test](Tests/MiniReduxTests/ObservableDelegation.swift)

## How to handle a list view with each item having its own store

The parent can maintain a list of child stores. To prevent unnecessary re-initialization and allow children to handle internal state independently, use the [updateInPlace](Sources/MiniRedux/Helpers/Array+UpdateInPlace.swift) helper. This ensures the child store object is reused as long as its ID remains constant.

See example in [this unit test](Tests/MiniReduxTests/ObservableList.swift)


## Apps using MiniRedux

Cipher Challenge is a cipher decoding game built on this architecture. See the [Swift source code](https://github.com/ba01ei/cipher-app).

The game can be downloaded [here](https://cipher.theiosapp.com)

## Comparison to TCA

TCA is a comprehensive framework, whereas MiniRedux is a minimalist implementation inspired by its philosophy.

### State Management
TCA uses a `struct` for state, providing automatic `Equatable` conformance and easier debugging. MiniRedux uses properties on a class, leveraging the Swift `@Observable` macro directly (TCA uses its own `@ObservableState`). To facilitate debugging, MiniRedux stores provide a `reflection` property to compare state changes.

### Reducer Structure
In TCA, the reducer is a separate `struct`, favoring "composition over inheritance." MiniRedux requires subclassing `BaseStore` and overriding the `reduce` function. This reduces boilerplate by maintaining logic and state in a single type.

### Composition & Scoping
TCA uses "scoping" to derive child stores from a slice of parent state, allowing a single tree of state. In MiniRedux, children stores are directly owned by parents. While less elegant, it is simpler to implement and carries less performance overhead, and the entire state tree is still available through the `reflection` property.

### Testing
TCA has mature testing infrastructure (like `TestStore`). MiniRedux is designed for testability but currently offers fewer helper utilities, which can be improved in the future.

## Pre-Observation Implementation

An earlier implementation of this library exists for iOS versions below 17, which doesn't rely on the `@Observable` macro. Its state management is more similar to TCA's `struct`-based approach.

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

Return a `Task` in the `reduce` function to run asynchronously, calling `send()` to trigger subsequent actions.

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
// provide an initialAction during initialization to trigger work immediately
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

This [example](Tests/MiniReduxTests/PreObervation/Delegation.swift) shows how a parent store can communicate with a child store in both directions.

If a parent store contains a child store, internal updates to the child won't automatically trigger a parent state update. This is because `Equatable` comparison for stores depends on their initial states. This separation helps prevent unnecessary view re-renders.

### Lists of child stores 

MiniRedux doesn't offer `.scope()`, but you can still maintain parent-child relationships within dynamic lists.

Check this [comparison](https://www.diffchecker.com/8s9ip7My/) between TCA and MiniRedux. TCA's `.scope()` is slightly more concise, but the functional result is similar.

See the [list unit test](Tests/MiniReduxTests/PreObservation/List.swift).

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
