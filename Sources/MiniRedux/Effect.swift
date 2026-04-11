import Combine
import Foundation

/// For simplicity of the implemenation:
/// - If `.merge` has an `id`, then the top level `id` will be used for all effects inside the merge.
/// - `cancelInFlight` only works when `id` is passed and non-nil. If it is true, it will cancel all the existing effects using that same id.
/// - We can use either `.run(id: "a") { ... }` or `.run { ... }.cancellable(id: "a")`. They are the same.
public enum Effect<Action: Sendable> {
  case none
  case run(id: (any Hashable)?, cancelInFlight: Bool = false, _ run: @Sendable ((Action) async -> Void) async -> Void)
  case publisher(id: (any Hashable)? = nil, cancelInFlight: Bool = false, _ publisher: () -> any Publisher<Action, Never>)
  case cancel(id: any Hashable)
  case merge(id: (any Hashable)? = nil, cancelInFlight: Bool = false, [Self])
  case concatenate(id: (any Hashable)? = nil, cancelInFlight: Bool = false, [Self])

  @inlinable public static func merge(_ effects: Self...) -> Effect {
    return .merge(id: nil, effects)
  }

  @inlinable public static func concatenate(_ effects: Self...) -> Effect {
    return .concatenate(id: nil, effects)
  }

  @inlinable public static func run(_ operation: @escaping @Sendable ((Action) async -> Void) async -> Void) -> Effect {
    return .run(id: nil, operation)
  }

  func perform(
    cancellablesDict: inout [AnyHashable: Set<AnyCancellable>], send: @escaping @MainActor (Action) async -> Void
  ) {
    switch self {
    case .none:
      break

    case .cancel(let id):
      cancellablesDict[AnyHashable(id)]?.forEach { $0.cancel() }
      cancellablesDict.removeValue(forKey: AnyHashable(id))

    case .run(let id, let cancelInFlight, let run):
      if let id, cancelInFlight {
        Self.cancel(id: id).perform(cancellablesDict: &cancellablesDict, send: send)
      }
      Task.detached {
        await run(send)
      }
      .toCancellable()
      .store(id: id.map { AnyHashable($0) }, in: &cancellablesDict)

    case .publisher(let id, let cancelInFlight, let publisher):
      if let id, cancelInFlight {
        Self.cancel(id: id).perform(cancellablesDict: &cancellablesDict, send: send)
      }
      publisher().sink { action in
        Task {
          await send(action)
        }
      }
      .store(id: id.map { AnyHashable($0) }, in: &cancellablesDict)

    case .merge(let id, let cancelInFlight, let effects):
      if let id, cancelInFlight {
        Self.cancel(id: id).perform(cancellablesDict: &cancellablesDict, send: send)
      }
      for effect in effects {
        let effectToUse = if let id {
          effect.cancellable(id: id, cancelInFlight: cancelInFlight)
        } else {
          effect
        }
        effectToUse.perform(cancellablesDict: &cancellablesDict, send: send)
      }

    case .concatenate(let id, let cancelInFlight, let effects):
      if let id, cancelInFlight {
        Self.cancel(id: id).perform(cancellablesDict: &cancellablesDict, send: send)
      }
      let operations: [@Sendable ((Action) async -> Void) async -> Void] = effects.compactMap {
        if case .run(_, _, let run) = $0 { return run }
        return nil
      }
      guard !operations.isEmpty else { break }
      Task.detached {
        for operation in operations {
          await operation(send)
        }
      }
      .toCancellable()
      .store(id: id.map { AnyHashable($0) }, in: &cancellablesDict)

    }
  }
  
  // override the id and cancelInFlight of an effect
  public func cancellable(id: some Hashable, cancelInFlight: Bool = false) -> Self {
    switch self {
    case .none, .cancel:
      return self

    case .run(_, _, let run):
      return .run(id: id, cancelInFlight: cancelInFlight, run)

    case .publisher(_, _, let publisher):
      return .publisher(id: id, cancelInFlight: cancelInFlight, publisher)

    case .merge(_, _, let effects):
      return .merge(id: id, cancelInFlight: cancelInFlight, effects)

    case .concatenate(_, _, let effects):
      return .concatenate(id: id, cancelInFlight: cancelInFlight, effects)

    }
  }
}

extension AnyCancellable {
  func store(id: AnyHashable?, in cancellablesDict: inout [AnyHashable: Set<AnyCancellable>]) {
    let key = id ?? AnyHashable("")
    if cancellablesDict[key] == nil {
      cancellablesDict[key] = Set()
    }
    cancellablesDict[key]?.insert(self)
  }
}

/// Allow auto cancellation of Tasks
extension Task {
  public func toCancellable() -> AnyCancellable {
    return AnyCancellable(cancel)
  }
}
