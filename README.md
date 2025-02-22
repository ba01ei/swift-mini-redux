# Mini Redux Architecture

A minimal implementation of the Redux pattern in Swift.

Inspired by TCA, i.e. [The Composable Architecture by PointFree](https://github.com/pointfreeco/swift-composable-architecture).

This is a minimalist version of TCA that

1. The entire library is in [two](Sources/MiniRedux/Store.swift) [files](Sources/MiniRedux/Effect.swift)
2. It doesn't depend on Swift Macro
3. You can use it in iPad Swift Playground

It's not a replacement for TCA. For a comprehensive project, we recommend using TCA. This library is made for:

1. Quick prototyping an idea, in which case you can also just copy/paste the code without adding the package dependency
2. Small project created in Swift Playground on iPad or MacOS 

It supports the basic concepts of Redux: Store, State, Action, Reducer, and Side Effect. It doesn't support some advanced features of TCA, like scoping reducers, Observable architecture, and navigation tools, etc. The APIs are very similar to TCA, so you can also prototype with this first and migrate to TCA easily if the project starts to grow bigger.

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

```
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

## More on why

A question is why do you need this architecture for a small project. For a quick prototype or small side project, why not just use vanilla SwiftUI?

In my experience from building both small side projects, there are reasons to have a good structure even for a 100 line single screen simple app:

1. If it's side project, despite an intention to keep it small and simple, it can and will grow, and without a structure it will grow messy.
2. It reduces cognitive load on decisions. Even when we say vanilla SwiftUI, there are still many ways to do things. Do you use @State or @ObservableObject or @Observable? If there is a networking call, do you trigger it in the view struct or an object observed by the view? Do you use Combine or AsyncStream if there is any ongoing subscription?

Then why Redux/TCA over MVVM?

I believe Redux and MVVM are not that different. They are both declarative, reactive, works well with SwiftUI. The cool things about Redux/TCA are:

1. Clear and consistent pattern. E.g. every parameter affecting UI is in the State, and every process that updates the State goes through Actions. With MVVM I've seen different people doing it in many ways since a view model seems to be more open ended, and later it's hard to find things and troubleshoot bugs. 
2. The Side Effect even in its simplest form (as in this repo) is very powerful for managing asynchronous processes. It's easier to understand and reason than Combine/Rx, and it's more powerful than out-of-box async/await/AsyncStream.

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
