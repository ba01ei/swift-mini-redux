//
//  ObservableStore.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 12/24/25.
//

import Combine
import Observation

/**
 A protocol for a Store object that can be observable by a SwiftUI View.
 Usage:
 ```
 import SwiftUI
 import Combine // this is needed for AnyCancellable
 
 @Observable class AStore: BaseStore<AStore.Action> {
   // MARK: - State
   var text = ""
   var number = 1
 
   // MARK: - Action
   enum Action {
     case action1
   }
 
   // MARK: - Reducer
   override func reduce(_ action: Action) -> Effect<Action> {
     switch action {
       case .action1:
         store.text = "..."
         return .none
     }
   }
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

@available(macOS 14.0, iOS 17.0, *)
@Observable open class BaseStore<Action>: ObservableStore {
  public init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    self.delegatedActionHandler = delegatedActionHandler
  }

  open func reduce(_ action: Action) -> Effect<Action> {
    // to be implemented by subclass
    fatalError("not implemented")
  }

  @ObservationIgnored public var delegatedActionHandler: ((Action) -> Void)?
  @ObservationIgnored public var cancellables: [String : Set<AnyCancellable>] = [:]
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
