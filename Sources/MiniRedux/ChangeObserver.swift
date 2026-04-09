//
//  ChangeObserver.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 4/8/26.
//

public struct ChangeObserver: @unchecked Sendable {
  let captureValue: @MainActor () -> Any
  let notify: @MainActor (_ oldValue: Any) -> Void
}

@available(macOS 14.0, iOS 17.0, *)
@MainActor public protocol ChangeObservable: AnyObject {
  var changeObservers: [ChangeObserver] { get set }
}

@available(macOS 14.0, iOS 17.0, *)
public extension ChangeObservable {
  /// Register a handler that fires when a property changes after a `reduce`.
  /// Typically called in `init`. The handler receives the old and new values.
  /// ```
  /// override init() {
  ///   super.init()
  ///   onChangeOf(\.count) { oldValue, newValue in
  ///     print("count changed from \(oldValue) to \(newValue)")
  ///   }
  /// }
  /// ```
  func onChangeOf<V: Equatable>(_ keyPath: KeyPath<Self, V>, handler: @escaping (_ oldValue: V, _ newValue: V) -> Void) {
    changeObservers.append(ChangeObserver(
      captureValue: { [weak self] in
        self?[keyPath: keyPath] as Any
      },
      notify: { [weak self] oldValue in
        guard let self, let oldValue = oldValue as? V else { return }
        let newValue = self[keyPath: keyPath]
        if oldValue != newValue {
          handler(oldValue, newValue)
        }
      }
    ))
  }
}
