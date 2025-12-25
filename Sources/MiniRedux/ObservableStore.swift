//
//  ObservableStore.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 12/24/25.
//

import Combine

/**
 A protocol for a Store object that can be observable by a SwiftUI View.
 Usage:
 ```
 @Observable class AStore: ObservableStore {
   // MARK: - State
   var text = ""
   var number = 1
 
   // MARK: - Action
   enum Action {
     case action1
   }
 
   // MARK: - Reducer
   func reduce(_ action: Action) -> Effect<Action> {
     switch action {
       case .action1:
         store.text = "..."
         return .none
     }
   }
 
   // MARK: - Protocol conformance
   var delegatedActionHandler: ((Action) -> Void)?
   var cancellables: [String : Set<AnyCancellable>] = [:]
 }
 
 struct AView: View {
   let store: AStore
   var body: some View {
     Text(store.text) // this will be automatically observing
   }
 }
 ```
 */
@MainActor public protocol ObservableStore: AnyObject {
  associatedtype Action: Sendable
  func reduce(_ action: Action) -> Effect<Action>
  var delegatedActionHandler: ((Action) -> Void)? { get }
  var cancellables: [String: Set<AnyCancellable>] { get set }
}

extension ObservableStore {
  public func send(_ action: Action) {
    let result = reduce(action)
    result.perform(cancellablesDict: &cancellables, send: { [weak self] a in
      self?.send(a)
    })

    delegatedActionHandler?(action)
  }
}
