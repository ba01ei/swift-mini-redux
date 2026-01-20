//
//  TableViewRepresentable.swift
//  MiniReduxExample
//
//  Created by Bao Lei on 1/19/26.
//

import SwiftUI

struct TableViewRepresentable: UIViewRepresentable {

  let store: TableStore
  
  func makeUIView(context: Context) -> UITableView {
    let tableView = TableViewWithObservation()
    tableView.dataSource = context.coordinator
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 44
    context.coordinator.tableView = tableView
    if #available(iOS 26, *) {
      tableView.store = store
    } else {
      context.coordinator.observeStore()
    }
    return tableView
  }

  func updateUIView(_ uiView: UITableView, context: Context) {
    if #unavailable(iOS 26) {
      uiView.reloadData()
    }
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

    // backward compatibility for below iOS 26
    func observeStore() {
      if #unavailable(iOS 26) {
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

// Custom UITableView subclass for iOS 26+ automatic observation
class TableViewWithObservation: UITableView {
  var store: TableStore?

  @available(iOS 26, *)
  override func updateProperties() {
    super.updateProperties()
    if let store {
      _ = store.content
      // iOS 26 automatically tracks and updates
      self.reloadData()
    }
  }
}
