# Mini Redux Architecture

A minimal implementation of the Redux pattern in Swift.

Inspired by TCA, i.e. [The Composable Architecture by PointFree](https://github.com/pointfreeco/swift-composable-architecture).

## Examples

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

Return a Task in the reducer function to run asynchronously, and call send when the result is ready

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

```swift
struct Child: Reducer {
  struct State: Equatable {
    var value = 0
  }
  enum Action: Sendable {
    case valueUpdated(Int)
  }
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State()) { state, action, send in
      switch action {
      case .valueUpdated(let value):
        state.value = value
        return .none
      }
    }
  }
}

struct Parent: Reducer {
  struct State: Equatable {
    var value = 0
  }
  enum Action {
    case childActions(Child.Action)
  }
  @MainActor static func store(childStore: StoreOf<Child>) -> StoreOf<Self> {
    return StoreOf<Self>(initialState: State()) { state, action, send in
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

### A list of child stores
```
struct List: Reducer {
  struct State: Equatable {
    /// Child stores can live in the state of their parents.
    /// Updates of child item's store's state won't cause the parent or siblings to re-render 
    var items: [StoreOf<Item>] = []
  }
  
  enum Action {
    case itemsFetched([Item.State])
    case itemAction(id: String, Item.Action)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State()) { state, action, send in
      switch action {

      case .itemsFetched(let items):
        updateList(originals: &state.items, newItems: items) { @MainActor item in
          return Item.store(item) { childAction in
            send(.itemAction(id: item.id, childAction))
          }
        }
        return .none
        
      case .itemAction(id: let id, let action):
        switch action {
        case .tapped:
          // handle tap action ...
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
  
  @MainActor static func store(_ initialState: State, delegatedActionHandler: @escaping (@MainActor (Action) -> Void)) -> StoreOf<Self> {
    return Store(initialState: initialState, initialAction: .initialized, delegateActionHandler: delegatedActionHandler) { state, action, send in
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
