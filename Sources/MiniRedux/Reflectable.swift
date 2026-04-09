//
//  Reflectable.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 4/8/26.
//

import Foundation

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
