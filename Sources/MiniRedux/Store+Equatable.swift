/// Being Equatable helps a list of stores to be used as sub-stores
extension Store: Equatable {
  /// Compare stores based on initial state instead of latest state
  /// So that the parent view can avoid unncessary re-renders
  nonisolated public static func == (lhs: Store<State, Action>, rhs: Store<State, Action>) -> Bool {
    return lhs.initialState == rhs.initialState
  }
}

extension Store: Identifiable where State: Identifiable {
  nonisolated public var id: State.ID {
    return initialState.id
  }
}

/// Update a list in place, re-use existing items as much as possible
/// This is useful for refreshing a list of stores based on new states fetched
@MainActor public func updateList<OriginalItem: Identifiable, NewItem: Identifiable>(
  originals: inout [OriginalItem],
  newItems: [NewItem],
  createItem: @MainActor (NewItem) -> OriginalItem)
where OriginalItem.ID == NewItem.ID {
  var index = 0
  let originalIdSet = Set(originals.map { $0.id })
  while index < originals.count && index < newItems.count {
    let newItem = newItems[index]
    if originals[index].id == newItem.id {
      index += 1
      continue
    }
    if originalIdSet.contains(newItem.id),
       let i = originals.firstIndex(where: { $0.id == newItem.id}) {
      /// A A
      /// B C index=1
      /// C D
      /// E B
      let matchingItem = originals.remove(at: i)
      originals.insert(matchingItem, at: index)
      index += 1
      continue
    } else {
      /// A A
      /// C C
      /// B D  index=1
      /// E B
      originals.insert(createItem(newItems[index]), at: index)
      index += 1
      continue
    }
  }
  /// A A
  /// B
  if index < originals.count {
    originals.removeSubrange(index ..< originals.count)
  }
  /// ```
  /// A A
  ///   B
  /// ```
  if index < newItems.count {
    originals.append(contentsOf: newItems[index ..< newItems.count].map { createItem($0) })
  }
}
