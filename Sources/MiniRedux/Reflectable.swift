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
          encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
          valueStr = String(data: (try? encoder.encode(childStore.reflection)) ?? Data(), encoding: .utf8) ?? "<encode failure>"
        } else {
          // use dump to ensure key order
          valueStr = ""
          dump(child.value, to: &valueStr)
          // use regex to remove leading "- " and trailing "\n"
          valueStr = valueStr
            .replacingOccurrences(of: "^(- )", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\n$", with: "", options: .regularExpression)
        }
        dict[label] = valueStr
      }
    }
  }
  
  /// Compare the current `reflection` against a previously captured one and return only the changed keys.
  /// The value for each changed key is a git-diff-style line diff: `+line` for inserts, `-line` for removes.
  /// Single-line values are treated as one line, so `"1" -> "123"` becomes `"-1 +123"`.
  func diff(_ previousReflection: [String: String]) -> [String: String] {
    let currentReflection = reflection
    var result: [String: String] = [:]
    let allKeys = Set(currentReflection.keys).union(previousReflection.keys)
    for key in allKeys {
      let previous = previousReflection[key] ?? ""
      let current = currentReflection[key] ?? ""
      guard previous != current else { continue }

      let previousLines = previous.split(separator: "\n", omittingEmptySubsequences: false)
      let currentLines = current.split(separator: "\n", omittingEmptySubsequences: false)
      result[key] = currentLines.difference(from: previousLines).map {
        switch $0 {
        case .insert(_, let e, _): "+\(e)"
        case .remove(_, let e, _): "-\(e)"
        }
      }.joined(separator: " ")
    }
    return result
  }
  
  public func _printChangesOnAction() -> Self {
    debug = true
    return self
  }
}
