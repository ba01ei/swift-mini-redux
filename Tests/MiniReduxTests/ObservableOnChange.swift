import Testing
import Foundation
import MiniRedux

@Observable class ChangeDetectionStore: BaseStore<ChangeDetectionStore.Action> {
  var count = 0
  var count2: Int? = nil
  var update = ""
  var update2 = ""

  override init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    super.init(delegatedActionHandler: delegatedActionHandler)
    onChangeOf(\.count) { [weak self] oldValue, newValue in
      self?.update = "\(oldValue) -> \(newValue)"
    }
    onChangeOf(\.count2) { [weak self] oldValue, newValue in
      self?.update2 = "\(oldValue, default: "nil") to \(newValue, default: "nil")"
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
      count2 = (count2 ?? 0) + 1
      return .none
    }
  }
}

@Observable class OnChangeEffectStore: BaseStore<OnChangeEffectStore.Action> {
  var count = 0
  var doubled = 0

  override init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    super.init(delegatedActionHandler: delegatedActionHandler)
    onChangeOf(\.count) { oldValue, newValue -> Effect<Action> in
      return .send(.updateDoubled(newValue * 2))
    }
  }

  enum Action {
    case increment
    case updateDoubled(Int)
  }

  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .increment:
      count += 1
      return .none
    case .updateDoubled(let value):
      doubled = value
      return .none
    }
  }
}

@Test func onChangeOfSingleProperty() async throws {
  let store = await ChangeDetectionStore()
  await store.send(.increment)
  await expectWithDelay { await store.update == "0 -> 1" }
  #expect(await store.count == 1)

  await store.send(.increment)
  await expectWithDelay { await store.update == "1 -> 2" }
  #expect(await store.count == 2)
}

@Test func onChangeOfMultipleProperties() async throws {
  let store = await ChangeDetectionStore()
  await store.send(.increment)
  await expectWithDelay { await store.update == "0 -> 1" }
  await store.send(.increment2)
  await expectWithDelay { await store.update2 == "nil to 1" }
  #expect(await store.count == 1)
  #expect(await store.count2 == 1)
}

@Test func onChangeOfDirectMutation() async throws {
  let store = await ChangeDetectionStore()
  await MainActor.run { store.count = 5 }
  await expectWithDelay { await store.update == "0 -> 5" }

  await MainActor.run { store.count = 10 }
  await expectWithDelay { await store.update == "5 -> 10" }
}

@Test func onChangeOfReturningEffect() async throws {
  let store = await OnChangeEffectStore()
  await store.send(.increment)
  await expectWithDelay { await store.doubled == 2 }
  #expect(await store.count == 1)

  await store.send(.increment)
  await expectWithDelay { await store.doubled == 4 }
  #expect(await store.count == 2)
}
