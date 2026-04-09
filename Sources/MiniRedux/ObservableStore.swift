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
@available(macOS 14.0, iOS 17.0, *)
@MainActor @Observable open class BaseStore<Action: Sendable> {
  public init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    self.delegatedActionHandler = delegatedActionHandler
  }

  open func reduce(_ action: Action) -> Effect<Action> {
    // to be implemented by subclass
    fatalError("not implemented")
  }

  /// Send an action to the store. The action will be processed by the reduce function.
  public func send(_ action: Action) {
    let result = reduce(action)
    result.perform(cancellablesDict: &cancellables, send: { [weak self] a in
      self?.send(a)
    })
    delegatedActionHandler?(action)
  }

  @ObservationIgnored public var delegatedActionHandler: ((Action) -> Void)?
  @ObservationIgnored public var cancellables: [String : Set<AnyCancellable>] = [:]
}

@MainActor private protocol Reflectable {
  var reflection: [String: String] { get }
}

@available(macOS 14.0, iOS 17.0, *)
extension BaseStore: Reflectable {
  /// A key value representation of the state for unit testing and debugging.
  /// To track state change, at the end of the reducer, add something like:
  /// `print("\(self) received action: \(action). new state: \(reflection)")`
  public var reflection: [String: String] {
    let mirror = Mirror(reflecting: self)
    return mirror.children.reduce(into: [:]) { dict, child in
      guard let label = child.label else { return }
      if label.starts(with: "_") && !label.contains("$") {
        var valueStr: String
        if let childStore = child.value as? Reflectable {
          let encoder = JSONEncoder()
          encoder.outputFormatting = [.sortedKeys]
          valueStr = String(data: (try? encoder.encode(childStore.reflection)) ?? Data(), encoding: .utf8) ?? "<encode failure>"
        } else {
          // use dump to ensure key order
          valueStr = ""
          dump(child.value, to: &valueStr)
        }
        dict[label] = valueStr
      }
    }
  }
}
