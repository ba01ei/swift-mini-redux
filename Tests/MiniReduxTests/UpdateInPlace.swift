import MiniRedux
import Testing

@Test func updateInPlace() async throws {
  
  struct Item: Identifiable, Equatable {
    let id: String
    let value: Int
  }
  
  var array = [Item(id: "a", value: 1), Item(id: "b", value: 2), Item(id: "d", value: 4)]
  array.updateInPlace(newItems: ["b", "c", "a"], newItemId: \.self) { index, newId in
    Item(id: newId, value: index)
  }
  #expect(array == [Item(id: "b", value: 2), Item(id: "c", value: 1), Item(id: "a", value: 1)])
}

@Test func updateInPlaceWithFilter() async throws {
  
  struct Item: Identifiable, Equatable {
    let section: Int
    let id: String
    let value: Int
  }
  
  var array = [
    Item(section: 0, id: "a", value: 1),
    Item(section: 0, id: "b", value: 2),
    Item(section: 0, id: "c", value: 3),
    Item(section: 1, id: "d", value: 4),
    Item(section: 1, id: "e", value: 5),
    Item(section: 1, id: "f", value: 6),
    Item(section: 2, id: "g", value: 7),
    Item(section: 2, id: "h", value: 8),
    Item(section: 2, id: "i", value: 9)
  ]

  // update items in section 1
  array.updateInPlace(newItems: ["d", "e", "ff"], newItemId: \.self, filter: { $0.section == 1}) { index, newId in
    Item(section: 1, id: newId, value: index)
  }
  #expect(array == [
    Item(section: 0, id: "a", value: 1),
    Item(section: 0, id: "b", value: 2),
    Item(section: 0, id: "c", value: 3),
    Item(section: 1, id: "d", value: 4),
    Item(section: 1, id: "e", value: 5),
    Item(section: 1, id: "ff", value: 5),
    Item(section: 2, id: "g", value: 7),
    Item(section: 2, id: "h", value: 8),
    Item(section: 2, id: "i", value: 9)
  ])
  
  // add more items to section 0
  array.updateInPlace(newItems: ["b", "a", "c", "cc", "ccc"], newItemId: \.self, filter: { $0.section == 0}) { index, newId in
    Item(section: 0, id: newId, value: index)
  }
  #expect(array == [
    Item(section: 0, id: "b", value: 2),
    Item(section: 0, id: "a", value: 1),
    Item(section: 0, id: "c", value: 3),
    Item(section: 0, id: "cc", value: 3),
    Item(section: 0, id: "ccc", value: 4),
    Item(section: 1, id: "d", value: 4),
    Item(section: 1, id: "e", value: 5),
    Item(section: 1, id: "ff", value: 5),
    Item(section: 2, id: "g", value: 7),
    Item(section: 2, id: "h", value: 8),
    Item(section: 2, id: "i", value: 9)
  ])
  
  // remove items from section 2
  array.updateInPlace(newItems: ["i"], newItemId: \.self, filter: { $0.section == 2}) { index, newId in
    Item(section: 2, id: newId, value: index)
  }
  #expect(array == [
    Item(section: 0, id: "b", value: 2),
    Item(section: 0, id: "a", value: 1),
    Item(section: 0, id: "c", value: 3),
    Item(section: 0, id: "cc", value: 3),
    Item(section: 0, id: "ccc", value: 4),
    Item(section: 1, id: "d", value: 4),
    Item(section: 1, id: "e", value: 5),
    Item(section: 1, id: "ff", value: 5),
    Item(section: 2, id: "i", value: 9)
  ])
}
