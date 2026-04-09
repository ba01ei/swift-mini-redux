import Testing
import Foundation
import MiniRedux

@Observable class OnChangeStore: BaseStore<OnChangeStore.Action> {
  var count = 0
  var count2 = 0
  var update = ""
  var update2 = ""

  override init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    super.init(delegatedActionHandler: delegatedActionHandler)
    onChangeOf(\.count) { [weak self] oldValue, newValue in
      self?.update = "\(oldValue) -> \(newValue)"
    }
    onChangeOf(\.count2) { [weak self] oldValue, newValue in
      self?.update2 = "\(oldValue) to \(newValue)"
    }
  }

  enum Action {
    case increment
    case increment2
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .increment:
      count += 1
      return .none
      
    case .increment2:
      count2 += 1
      return .none
    }
  }
}

@MainActor @Test func onChangeOfSingleProperty() async throws {
  let store = OnChangeStore()
  store.send(.increment)
  #expect(store.count == 1)
  #expect(store.update == "0 -> 1")

  store.send(.increment)
  #expect(store.count == 2)
  #expect(store.update == "1 -> 2")
}

@MainActor @Test func onChangeOfMultipleProperties() async throws {
  let store = OnChangeStore()
  store.send(.increment)
  store.send(.increment2)
  #expect(store.count == 1)
  #expect(store.count2 == 1)
  #expect(store.update == "0 -> 1")
  #expect(store.update2 == "0 to 1")
}
