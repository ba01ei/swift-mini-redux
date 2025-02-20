# Mini Redux Architecture

A minimal implementation of the Redux pattern in Swift.

Inspired by TCA, i.e. [The Composable Architecture by PointFree](https://github.com/pointfreeco/swift-composable-architecture).

This is a minimalist version of TCA that

1. The entire library is mostly in [one file](Sources/MiniRedux/MiniRedux.swift)
2. It doesn't depend on Swift Macro
3. You can use it in iPad Swift Playground

It's not a replacement for TCA. For a comprehensive project, we recommend using TCA. This library is useful for prototyping something quick. E.g. you can also just copy/paste the [code](Sources/MiniRedux/MiniRedux.swift) into a Playground, or a temporary project, without dealing with the package installation. Also since iPad Swift Playground doesn't support Swift Macro yet (as of Feb 2025), this library is an alternative to TCA for prototyping on iPad.

It supports the basic concepts of Redux: Store, State, Action, Reducer, and Side Effect (through Task or Combine). It doesn't support some advanced features of TCA, like scoping reducers, Observable architecture, and navigation tools, etc.

## Examples

### Basic example

The simplest counter app

```
import MiniRedux
import SwiftUI

struct Counter {
  struct State {
    var count = 0
  }
  enum Action {
    case increment
    case decrement
  }
  @MainActor static func store() -> Store<State, Action> {
    return Store(initialState: State()) { state, action, send in
      switch action {
      case .increment:
        state.count += 1
        return nil
      case .decrement:
        state.count -= 1
        return nil
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
        store.send(.increment)
      }
      Button("-") {
        store.send(.decrement)
      }
    }
  }
}
```

### Async Side Effect

Return a Task in the reducer function to run asynchronously, and call send when the result is ready

```
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
    return Store(initialState: RandomQuote()) { state, action, send in
      switch action {
      case .getQuoteTapped:
        state.text = "Loading..."
        return Task {
          guard let url = URL(string: "https://cipher.lei.fyi/quote") else { return }
          do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let result = try JSONDecoder().decode(Response.self, from: data)
            send(.quoteLoaded(result.quote + " - " + result.author))
          } catch {
            send(.quoteLoaded("Error: \(error)"))
          }
        }.toCancellables()
      case .quoteLoaded(let text):
        state.text = text
        return nil
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

```
@MainActor static func store() -> Store<State, Action> {
  // when creating a store, an initialAction can be passed so it will be called when the store is initialized
  return Store(initialState: State(), initialAction: .initialized) { state, action, send in
    switch action {
    case .initialized:
      return publisher.receive(on: DispatchQueue.main).sink { result in
        send(.resultUpdated(result))
      }
    }
 }
}
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
