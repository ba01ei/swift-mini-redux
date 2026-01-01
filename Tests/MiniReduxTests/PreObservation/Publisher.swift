@preconcurrency import Combine
import MiniRedux
import Testing
import Foundation

@Test func reducerWithPublisher() async throws {

  struct Reader: Reducer {
    struct State: Equatable {
      var value = 0
    }
    enum Action {
      case initialized
      case valuePublished(Int)
    }
    @MainActor static func store(_ valuePublisher: some Publisher<Int, Never>) -> StoreOf<Self> {
      return Store(initialState: State(), initialAction: .initialized) { state, action, send in
        switch action {
        case .initialized:
          return .publisher {
            valuePublisher.receive(on: DispatchQueue.main).map { value in
                .valuePublished(value)
            }
          }

        case .valuePublished(let value):
          state.value = value
          return .none

        }
      }
    }
  }

  let subject = CurrentValueSubject<Int, Never>(0)
  let store = await Reader.store(subject)
  
  subject.send(1)
  await expectWithDelay { await store.state.value == 1 }
  
  subject.send(2)
  await expectWithDelay { await store.state.value == 2 }
}
