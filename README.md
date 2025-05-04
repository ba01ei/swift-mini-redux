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

struct Parent: Reducer {
  struct State: Equatable {
    var value = 0
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
```

### A list of child stores
```swift
struct Cell: Reducer {
  struct State: Equatable, Identifiable {
    let id: Int
    var text: String? = nil
  }
  
  enum Action {
    case onAppear // sent in View.onAppear
    case onDisappear // sent in View.onDisappear
    case contentFetched(String)
    case tapped
  }
  
  @MainActor static func store(_ initialState: State, delegatedActionHandler: @escaping @MainActor @Sendable (Action) -> Void) -> StoreOf<Self> {
    return Store(initialState: initialState, delegateActionHandler: delegatedActionHandler) { state, action, send in
      switch action {
      case .onAppear:
        return .run { [id = state.id] send in
          await send(.contentFetched("Content of \(id) fetched at \(Date())"))
        }
        .cancellable(id: "cancellable")
        
      case .onDisappear:
        // also clean up memory intensive resources
        // when view moves out of visible area
        return .cancel(id: "cancellable")
        
      case .contentFetched(let content):
        state.text = content
        return .none
        
      case .tapped:
        return .none

      }
    }
  }
}

struct List: Reducer {
  struct State: Equatable {
    /// Child stores can live in the state of their parents.
    /// Updates of child item's store's state won't cause the parent or siblings to re-render
    var cellStores: [StoreOf<Cell>] = []
  }
  
  enum Action {
    case initialized
    case fetchRequested
    case itemsFetched([Cell.State])
    case cellAction(id: Int, Cell.Action)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State(), initialAction: .initialized) { state, action, send in
      switch action {
        
      case .initialized:
        return .run { send in
          // simulate periodical content update
          while true {
            await send(.fetchRequested)
            try? await Task.sleep(for: .seconds(1))
          }
        }

      case .fetchRequested:
        return .run { [state] send in
          await send(.itemsFetched(state.cellStores.map { Cell.State(id: $0.id) } + [.init(id: (state.cellStores.last?.id ?? 0) + 1)]))
        }
        .cancellable(id: "fetch", cancelInFlight: true)

      case .itemsFetched(let items):
        updateList(originals: &state.cellStores, newItems: items) { @MainActor item in
          return Cell.store(item) { cellAction in
            send(.cellAction(id: item.id, cellAction))
          }
        }
        return .none
        
      case .cellAction(let id, let cellAction):
        switch cellAction {
        case .tapped:
          print("item \(id) tapped")
          return .none

        default:
          return .none

        }
      }
    }
  }
}



struct ContentView: View {
  
  @ObservedObject var store = List.store()
  
  var body: some View {
    VStack {
      ScrollView {
        VStack {
          ForEach(store.state.cellStores) { cellStore in
            CellView(store: cellStore)
          }
        }
      }
    }
    .padding()
  }
}

struct CellView: View {
  @ObservedObject var store: StoreOf<Cell>
  var body: some View {
    Text(store.state.text ?? "")
      .onTapGesture {
        store.send(.tapped)
      }
      .onAppear { store.send(.onAppear) }
      .onDisappear { store.send(.onDisappear) }
  }
}
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
