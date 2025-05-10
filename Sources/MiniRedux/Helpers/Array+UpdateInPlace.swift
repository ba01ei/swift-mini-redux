extension Array where Element: Identifiable {

  /// Update a list in place, re-use existing items as much as possible
  /// This is useful for refreshing a list of stores based on new states fetched.
  ///  - parameter create: the closure to create new elements for the array, called only when necessary.
  public mutating func updateInPlace<NewItem: Identifiable>(
    newItems: [NewItem],
    create: (_ index: Int, NewItem) -> Element)
  where Element.ID == NewItem.ID {
    var index = 0
    let originalIdSet = Set(map { $0.id })
    while index < count && index < newItems.count {
      let newItem = newItems[index]
      if self[index].id == newItem.id {
        index += 1
        continue
      }
      if originalIdSet.contains(newItem.id),
         let i = self.firstIndex(where: { $0.id == newItem.id}) {
        /// A A
        /// B C index=1
        /// C D
        /// E B
        let matchingItem = remove(at: i)
        insert(matchingItem, at: index)
        index += 1
        continue
      } else {
        /// A A
        /// C C
        /// B D  index=1
        /// E B
        insert(create(index, newItems[index]), at: index)
        index += 1
        continue
      }
    }
    /// A A
    /// B
    if index < count {
      removeSubrange(index ..< count)
    }
    /// ```
    /// A A
    ///   B
    /// ```
    if index < newItems.count {
      append(contentsOf: newItems[index ..< newItems.count].enumerated().map { create($0, $1) })
    }
  }
}
