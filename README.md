# Mini Redux Architecture

A minimal implementation of the Redux pattern in Swift.

Inspired by [The Composable Architecture by PointFree](https://github.com/pointfreeco/swift-composable-architecture). For a more complete feature set, please check out The Composable Architecture.

This is a minimalist version of TCA that
1. The entire library is in one file
2. It doesn't depend on Swift Macro
3. You can use it in iPad Swift Playground

It's useful for prototyping something quick. You can also just copy/paste the code without dealing with the installation.

It supports the basic concepts of Redux (Store, State, Action, Reducer, Side Effect).

## Examples

### Basic setup

```
import MiniRedux
import SwiftUI

struct Counter: Reducer {
  struct State {
    var count = 0
  }
  enum Action {
    case increment
    case decrement
  }
  @MainActor static func store(_ initialState: State = State()) -> Store<State, Action> {
    return Store(initialState) { state, action, send in
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


### Async Call

Reduce a Task in the reducer function to run asynchronously, and call send when the result is ready

```
struct RandomQuote: Reducer {
 struct State {
   var text = ""
 }
 enum Action {
   case getQuoteTapped
   case quoteUpdated(String)
 }
  @MainActor static func store(_ initialState: State = State()) -> Store<State, Action> {
   return Store(initialState) { state, action, send in
     switch action {
     case .getQuoteTapped:
       state.text = "Loading..."
       return Task {
         guard let url = URL(string: "https://cipher.lei.fyi/quote?pageId=\(Int.random(in: 1...2667))") else { return }
         do {
           let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
           let result = try JSONDecoder().decode(Response.self, from: data)
           send(.quoteUpdated(result.quote + " - " + result.author))
         } catch {
           send(.quoteUpdated("Error: \(error)"))
         }
       }.toCancellables()
     case .quoteUpdated(let text):
       state.text = text
       return nil
     }
   }
 }
}

struct Response: Codable {
 let quote: String
 let author: String
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
@MainActor static func store(_ initialState: State = State()) -> Store<State, Action> {
  // when creating a store, an initialAction can be passed so it will be called when the store is initialized
  return Store(initialState, initialAction: .initialized) { state, action, send in
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
