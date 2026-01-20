import SwiftUI
import UIKit
import MiniRedux

struct TableView: View {
  let store: TableStore

  var body: some View {
    VStack {
      HStack {
        if store.isLoading {
          ProgressView()
            .padding()
        }
        Spacer()
        Button("Add") {
          store.send(.addTapped)
        }
        .padding()
      }
      TableViewRepresentable(store: store)
    }
  }
}

struct TableViewRepresentable: UIViewRepresentable {

  let store: TableStore
  
  func makeUIView(context: Context) -> UITableView {
    let tableView = UITableView()
    tableView.dataSource = context.coordinator
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 44
    context.coordinator.tableView = tableView
    context.coordinator.observeStore()
    return tableView
  }

  func updateUIView(_ uiView: UITableView, context: Context) {
    uiView.reloadData()
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(store: store)
  }

  class Coordinator: NSObject, UITableViewDataSource {
    let store: TableStore
    weak var tableView: UITableView?

    init(store: TableStore) {
      self.store = store
    }

    func observeStore() {
      withObservationTracking {
        // Access the store property to register observation
        _ = store.content
      } onChange: {
        // When content changes, reload the table on main thread
        Task { @MainActor in
          self.tableView?.reloadData()
          // Re-establish observation for next change
          self.observeStore()
        }
      }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return store.content.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
      cell.textLabel?.text = store.content[indexPath.row]
      cell.textLabel?.numberOfLines = 0
      cell.textLabel?.lineBreakMode = .byWordWrapping
      return cell
    }
  }
}
