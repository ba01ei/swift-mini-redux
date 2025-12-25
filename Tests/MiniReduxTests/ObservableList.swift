//
//  List.swift
//  swift-mini-redux
//
//  Created by Bao Lei on 5/3/25.
//

import MiniRedux
import SwiftUI
import Testing
import Combine

@Observable class ListStore: ObservableStore {
  // MARK: State
  var items: [ItemStore] = []
  var lastTapped: String? = nil
  
  // MARK: Action
  enum Action {
    case itemsFetched([(id: String, text: String?)])
    case itemAction(id: String, ItemStore.Action)
  }
  
  func reduce(_ action: Action) -> Effect<Action> {
    switch action {
      
    case .itemsFetched(let fetchedItems):
      items.updateInPlace(newItems: fetchedItems, newItemId: \.id) { _, item in
        return ItemStore(id: item.id, text: item.text) { [weak self] childAction in
          self?.send(.itemAction(id: item.id, childAction))
        }
      }
      return .none
      
    case .itemAction(id: let id, let action):
      switch action {
      case .tapped:
        lastTapped = id
        return .none
        
      default:
        return .none
        
      }
    }
  }
  
  // MARK: Comformance
  var delegatedActionHandler: ((Action) -> Void)?
  var cancellables: [String : Set<AnyCancellable>] = [:]
}

@Observable class ItemStore: ObservableStore, Identifiable {
  let id: String
  var text: String? = nil
  init(id: String, text: String? = nil, delegatedActionHandler: ((Action) -> Void)? = nil) {
    self.id = id
    self.text = text
    self.delegatedActionHandler = delegatedActionHandler
    send(.initialized)
  }
  
  enum Action {
    case initialized
    case contentFetched(String)
    case tapped
  }
  
  func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .initialized:
      return .run { [id] send in
        await send(.contentFetched("Content of \(id) fetched at \(Date())"))
      }
      
    case .contentFetched(let content):
      text = content
      return .none
      
    case .tapped:
      return .none
      
    }
  }
  
  var delegatedActionHandler: ((Action) -> Void)?
  var cancellables: [String : Set<AnyCancellable>] = [:]
  
}

@Test func observableList() async throws {
  let store = await ListStore()
  await store.send(.itemsFetched([(id: "1", text: nil), (id: "2", text: nil)]))
  await expectWithDelay { await store.items.count == 2 }
  await expectWithDelay { await store.items.first?.text != nil }
  let firstItemContent = await store.items.first?.text
  
  await store.send(.itemsFetched([(id: "1", text: nil), (id: "2", text: nil), (id: "3", text: nil)]))
  await expectWithDelay { await store.items.count == 3 }
  await expectWithDelay { await store.items.last?.text != nil }
  // make sure that item with id=1 is not recreated
  #expect(await store.items.first?.text == firstItemContent)
  
  await store.send(.itemsFetched([(id: "4", text: nil), (id: "1", text: nil)]))
  await expectWithDelay { await store.items.count == 2 }
  await expectWithDelay { await store.items.first?.text != nil }
  #expect(await store.items.last?.text == firstItemContent)
  
  await store.items.first?.send(.tapped)
  #expect(await store.lastTapped == "4")
}

