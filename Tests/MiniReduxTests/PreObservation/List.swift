//
//  List.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 5/3/25.
//

import MiniRedux
import SwiftUI
import Testing

@Test func list() async throws {

  struct List: Reducer {
    struct State: Equatable {
      var items: [StoreOf<Item>] = []
      var lastTapped: String? = nil
    }
    
    enum Action {
      case itemsFetched([Item.State])
      case itemAction(id: String, Item.Action)
    }
    
    @MainActor static func store() -> StoreOf<Self> {
      return Store(initialState: State()) { state, action, send in
        switch action {

        case .itemsFetched(let items):
          state.items.updateInPlace(newItems: items) { _, item in
            return Item.store(item).delegate { childAction in
              send(.itemAction(id: item.id, childAction))
            }
          }
          return .none
          
        case .itemAction(id: let id, let action):
          switch action {
          case .tapped:
            state.lastTapped = id
            return .none

          default:
            return .none

          }
        }
      }
    }
  }
  
  struct Item: Reducer {
    struct State: Equatable, Identifiable {
      let id: String
      var text: String? = nil
    }
    
    enum Action {
      case initialized
      case contentFetched(String)
      case tapped
    }
    
    @MainActor static func store(_ initialState: State) -> StoreOf<Self> {
      return Store(initialState: initialState, initialAction: .initialized) { state, action, send in
        switch action {
        case .initialized:
          return .run { [id = state.id] send in
            await send(.contentFetched("Content of \(id) fetched at \(Date())"))
          }
          
        case .contentFetched(let content):
          state.text = content
          return .none
          
        case .tapped:
          return .none

        }
      }
    }
  }
  
  let store = await List.store()
  await store.send(.itemsFetched([.init(id: "1"), .init(id: "2")]))
  await expectWithDelay { await store.state.items.count == 2 }
  await expectWithDelay { await store.state.items.first?.state.text != nil }
  let firstItemContent = await store.state.items.first?.state.text
  
  await store.send(.itemsFetched([.init(id: "1"), .init(id: "2"), .init(id: "3")]))
  await expectWithDelay { await store.state.items.count == 3 }
  await expectWithDelay { await store.state.items.last?.state.text != nil }
  // make sure that item with id=1 is not recreated
  #expect(await store.state.items.first?.state.text == firstItemContent)
  
  await store.send(.itemsFetched([.init(id: "4"), .init(id: "1")]))
  await expectWithDelay { await store.state.items.count == 2 }
  await expectWithDelay { await store.state.items.first?.state.text != nil }
  #expect(await store.state.items.last?.state.text == firstItemContent)
  
  await store.state.items.first?.send(.tapped)
  #expect(await store.state.lastTapped == "4")
}

