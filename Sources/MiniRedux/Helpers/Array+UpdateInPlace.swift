extension Array where Element: Identifiable {

  /// Update a list in place, re-use existing items as much as possible
  /// This is useful for refreshing a list of stores based on new states fetched.
  ///  - parameter create: the closure to create new elements for the array, called only when necessary.
  ///  - parameter filter: only update the items that passes the check. This allows the scenario where newItems should only cover a subset of the original list
  public mutating func updateInPlace<NewItem: Identifiable>(
    newItems: [NewItem],
    filter: (Element) -> Bool = { _ in return true },
    create: (_ index: Int, _ newItem: NewItem) -> Element)
  where Element.ID == NewItem.ID {
    updateInPlace(newItems: newItems, newItemId: \.id, filter: filter, create: create)
  }
  
  /// Update a list in place, re-use existing items as much as possible
  /// This is useful for refreshing a list of stores based on new states fetched.
  ///  - parameter newItemId: the closure or keypath to return an id from the newItems' item, to match with the ID in original array
  ///  - parameter create: the closure to create new elements for the array, called only when necessary.
  ///  - parameter filter: only update the items that passes the check. This allows the scenario where newItems should only cover a subset of the original list
  public mutating func updateInPlace<NewItem>(
    newItems: [NewItem],
    newItemId: (NewItem) -> Element.ID,
    filter: (Element) -> Bool = { _ in return true },
    create: (_ index: Int, _ newItem: NewItem) -> Element
  ) {
    var originalArrayIndex = 0
    var newArrayIndex = 0
    let originalIdSet = Set(map { $0.id })
    while originalArrayIndex < count && newArrayIndex < newItems.count {
      if !filter(self[originalArrayIndex]) {
        originalArrayIndex += 1
        continue
      }
      
      let newItem = newItems[newArrayIndex]
      let newId = newItemId(newItem)
      if self[originalArrayIndex].id == newId {
        originalArrayIndex += 1
        newArrayIndex += 1
        continue
      }
      if originalIdSet.contains(newId),
         let i = self.firstIndex(where: { $0.id == newId}) {
        /// A A
        /// B C index=1
        /// C D
        /// E B
        let matchingItem = remove(at: i)
        insert(matchingItem, at: originalArrayIndex)
        originalArrayIndex += 1
        newArrayIndex += 1
        continue
      } else {
        /// A A
        /// C C
        /// B D  index=1
        /// E B
        insert(create(originalArrayIndex, newItems[newArrayIndex]), at: originalArrayIndex)
        originalArrayIndex += 1
        newArrayIndex += 1
        continue
      }
    }
    /// A A
    /// B
    for i in (originalArrayIndex..<count).reversed() {
      if filter(self[i]) {
        remove(at: i)
      }
    }
    /// ```
    /// A A
    ///   B
    /// ```
    if newArrayIndex < newItems.count {
      let insertIndex = (lastIndex(where: { filter($0) }) ?? count - 1) + 1
      insert(contentsOf: newItems[newArrayIndex ..< newItems.count].enumerated().map { create($0 + insertIndex, $1) }, at: insertIndex)
    }
  }
}
