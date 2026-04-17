//
//  ObservableStore.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 12/24/25.
//

import Foundation
import Combine
import Observation

/**
 A store based on reducer pattern that is observable by a SwiftUI View.
 Usage:
 ```
 import MiniRedux
 import SwiftUI

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

// MARK: - BaseStore

@available(macOS 14.0, iOS 17.0, *)
@MainActor @Observable open class BaseStore<Action: Sendable>: ChangeObservable {
  public init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    self.delegatedActionHandler = delegatedActionHandler
  }

  open func reduce(_ action: Action) -> Effect<Action> {
    // to be implemented by subclass
    fatalError("not implemented")
  }

  /// Send an action to the store. The action will be processed by the reduce function.
  public func send(_ action: Action) {
    sendAndForward(action)
    delegatedActionHandler?(action)
  }

  internal func sendWithoutDelegatingOrForwarding(_ action: Action) {
    let result = reduce(action)
    result.perform(cancellablesDict: &cancellables, send: { [weak self] a in
      self?.send(a)
    })
  }

  internal func sendAndForward(_ action: Action) {
    sendWithoutDelegatingOrForwarding(action)
    for childActionForward in childActionForwardList {
      childActionForward(action)
    }
  }

  /// Set up parent -> child action forwarding, when both parent and child are `BaseStore`
  /// Assuming both parent and child are BaseStore, and parent has an action that is associated to the child's action.
  /// With this, when that specific parent action is sent, the associated child action is also sent to the child.
  /// Call this on the child store.
  /// ```swift
  /// // inside a parent store
  /// self.childStore = ChildStore(...)
  ///   .forwardParentAction(from: self, {
  ///     if case .childActions(let childAction) = action { childAction } else { nil }
  ///   })
  /// ```
  public func forwardParentAction<ParentAction: Sendable>(from parentStore: BaseStore<ParentAction>, _ extractChildAction: @escaping (ParentAction) -> Action?) -> Self {
    parentStore.childActionForwardList.append { [weak self] parentAction in
      if let childAction = extractChildAction(parentAction) {
        self?.sendAndForward(childAction) // just don't delegate back, otherwise we get double call
      }
    }
    return self
  }

  /// Set up child -> parent delegation.
  /// Assuming both parent and child are BaseStore, and parent has an action that is associated to the child's action.
  /// With this, when any child action is sent, the associated parent action is also triggered.
  /// Call this on the child store:
  /// ```swift
  /// // inside a parent store
  /// self.childStore = ChildStore(...)
  ///   .delegateAction(to: self, {
  ///     ParentAction.childAction($0)
  ///   })
  /// ```
  /// If the parent is not a `BaseStore`, then directly set `delegatedActionHandler` with a custom closure.
  /// ```swift
  /// childStore = ...
  /// childStore.delegateActionHandler = { [weak self] childAction in
  ///   ... // any custom logic
  /// }
  /// ```
  public func delegateAction<ParentAction>(to parent: BaseStore<ParentAction>, _ buildParentAction: @escaping (Action) -> ParentAction) -> Self {
    delegatedActionHandler = { [weak parent] action in
      let parentAction = buildParentAction(action)
      parent?.sendWithoutDelegatingOrForwarding(parentAction)
      parent?.delegatedActionHandler?(parentAction)
    }
    return self
  }

  @ObservationIgnored public var delegatedActionHandler: ((Action) -> Void)?
  @ObservationIgnored var cancellables: [AnyHashable: Set<AnyCancellable>] = [:]
  @ObservationIgnored var childActionForwardList: [(Action) -> Void] = []
  @ObservationIgnored public var onChangeContinuations: [AsyncStream<Void>.Continuation] = []

  deinit {
    for continuation in onChangeContinuations {
      continuation.finish()
    }
  }
}
