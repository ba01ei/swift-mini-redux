import SwiftUI
import UIKit

struct TableView: UIViewRepresentable {
  
  let store: TableStore
  
  func makeUIView(context: Context) -> UITableView {
    let tableView = UITableView()
    tableView.dataSource = context.coordinator
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    return tableView
  }
  
  func updateUIView(_ uiView: UITableView, context: Context) {
    // No updates needed for static content
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  class Coordinator: NSObject, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
      cell.textLabel?.text = "\(indexPath.row + 1)"
      return cell
    }
  }
}
