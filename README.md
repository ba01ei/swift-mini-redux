# Mini Redux Architecture

A minimal implementation of the Redux pattern in Swift.

Inspired by TCA, i.e. [The Composable Architecture by PointFree](https://github.com/pointfreeco/swift-composable-architecture).

## Examples

### Basic example

The simplest counter app

```swift
import MiniRedux
import SwiftUI

struct Counter {
  struct State {
    var count = 0
  }
  enum Action {
    case incrementTapped
    case decrementTapped
  }
  @MainActor static func store() -> Store<State, Action> {
    return Store(initialState: State()) { state, action in
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

Return a Task in the reducer function to run asynchronously, and call send when the result is ready

```swift
struct RandomQuote {
  struct State {
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
  @MainActor static func store() -> Store<State, Action> {
    return Store(initialState: State()) { state, action in
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

You can also return a cancellable from a Combine subscription.

```swift
@MainActor static func store() -> Store<State, Action> {
  // when creating a store, an initialAction can be passed so it will be called when the store is initialized
  return Store(initialState: State(), initialAction: .initialized) { state, action in
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

```swift
struct Child: Reducer {
  struct State {
    var value = 0
  }
  enum Action: Sendable {
    case valueUpdated(Int)
  }
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State()) { state, action in
      switch action {
      case .valueUpdated(let value):
        state.value = value
        return .none
      }
    }
  }
}

struct Parent: Reducer {
  struct State {
    var value = 0
  }
  enum Action {
    case childActions(Child.Action)
  }
  @MainActor static func store(childStore: StoreOf<Child>) -> StoreOf<Self> {
    return StoreOf<Self>(initialState: State()) { state, action in
      switch action {
      case .childActions(let childAction):
        switch childAction {
        case .valueUpdated(let value):
          state.value = value
          return .none
        }
      }
    }
    .handleActions(from: childStore) { action in
      .childActions(action)
    }
  }
}
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
