//
//  ChangeObserver.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 4/8/26.
//

import Observation

@available(macOS 14.0, iOS 17.0, *)
@MainActor public protocol ChangeObservable: AnyObject {
  /// Implementation detail — used for lifecycle cleanup. Do not access directly.
  var onChangeContinuations: [AsyncStream<Void>.Continuation] { get set }
}

@available(macOS 14.0, iOS 17.0, *)
public extension ChangeObservable {
  /// Register a handler that fires when a property changes — whether through
  /// `send` or direct mutation. Uses Swift Observation under the hood.
  /// Typically called in `init`. The handler receives the old and new values.
  /// ```
  /// override init() {
  ///   super.init()
  ///   onChangeOf(\.count) { oldValue, newValue in
  ///     print("count changed from \(oldValue) to \(newValue)")
  ///   }
  /// }
  /// ```
  func onChangeOf<V: Equatable & Sendable>(
    _ keyPath: KeyPath<Self, V>,
    handler: @escaping @MainActor (_ oldValue: V, _ newValue: V) async -> Void
  ) {
    let (stream, continuation) = AsyncStream<Void>.makeStream()
    onChangeContinuations.append(continuation)

    startObservation(keyPath: keyPath, continuation: continuation)

    Task { @MainActor [weak self] in
      guard let initialSelf = self else { return }
      var oldValue = initialSelf[keyPath: keyPath]
      for await _ in stream {
        guard let self else { break }
        let newValue = self[keyPath: keyPath]
        if oldValue != newValue {
          await handler(oldValue, newValue)
        }
        oldValue = newValue
        self.startObservation(keyPath: keyPath, continuation: continuation)
      }
    }
  }

  /// Re-register `withObservationTracking` so the next mutation yields into the stream.
  private func startObservation<V>(
    keyPath: KeyPath<Self, V>,
    continuation: AsyncStream<Void>.Continuation
  ) {
    withObservationTracking {
      let _ = self[keyPath: keyPath]
    } onChange: {
      continuation.yield()
    }
  }
}
