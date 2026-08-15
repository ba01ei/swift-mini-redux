import UIKit

final class QuotesTableView: UITableView {
  private nonisolated enum Section: Hashable, Sendable {
    case main
  }

  let store: TableStore

  private var rowsByID: [QuoteRowStore.ID: QuoteRowStore] = [:]
  private lazy var diffableDataSource = makeDiffableDataSource()

  init(store: TableStore) {
    self.store = store
    super.init(frame: .zero, style: .plain)
    register(QuoteTableViewCell.self, forCellReuseIdentifier: QuoteTableViewCell.reuseIdentifier)
    rowHeight = UITableView.automaticDimension
    estimatedRowHeight = 44
    _ = diffableDataSource
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateProperties() {
    super.updateProperties()
    var snapshot = NSDiffableDataSourceSnapshot<Section, QuoteRowStore.ID>()
    snapshot.appendSections([.main])
    snapshot.appendItems(store.rows.map(\.id))
    diffableDataSource.apply(snapshot, animatingDifferences: window != nil)
  }

  private func makeDiffableDataSource() -> UITableViewDiffableDataSource<Section, QuoteRowStore.ID> {
    UITableViewDiffableDataSource(tableView: self) { [store] tableView, indexPath, rowID in
      guard
        let rowStore = store.rowsByID[rowID],
        let cell = tableView.dequeueReusableCell(
          withIdentifier: QuoteTableViewCell.reuseIdentifier,
          for: indexPath
        ) as? QuoteTableViewCell
      else {
        return UITableViewCell()
      }

      cell.configurationUpdateHandler = { cell, _ in
        guard let cell = cell as? QuoteTableViewCell else { return }
        cell.quoteLabel.text = rowStore.text
      }
      return cell
    }
  }
}
