import UIKit

final class QuotesTableView: UITableView {
  private nonisolated enum Section: Hashable, Sendable {
    case main
  }

  let store: QuotesStore

  private lazy var diffableDataSource = makeDiffableDataSource()

  init(store: QuotesStore) {
    self.store = store
    super.init(frame: .zero, style: .plain)
    register(QuoteRowViewUIKit.self, forCellReuseIdentifier: QuoteRowViewUIKit.reuseIdentifier)
    rowHeight = UITableView.automaticDimension
    estimatedRowHeight = 44
    _ = diffableDataSource
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if #unavailable(iOS 26.0) {
      applyRowsSnapshotIfNeeded()
    }
  }

  @available(iOS 26.0, *)
  override func updateProperties() {
    super.updateProperties()
    applyRowsSnapshotIfNeeded()
  }

  private func applyRowsSnapshotIfNeeded() {
    let rowIDs = store.rows.map(\.id)
    guard rowIDs != diffableDataSource.snapshot().itemIdentifiers else { return }

    var snapshot = NSDiffableDataSourceSnapshot<Section, QuoteRowStore.ID>()
    snapshot.appendSections([.main])
    snapshot.appendItems(rowIDs)
    diffableDataSource.apply(snapshot, animatingDifferences: window != nil)
  }

  private func makeDiffableDataSource() -> UITableViewDiffableDataSource<Section, QuoteRowStore.ID> {
    UITableViewDiffableDataSource(tableView: self) { [store] tableView, indexPath, rowID in
      guard
        let rowStore = store.rowsByID[rowID],
        let cell = tableView.dequeueReusableCell(
          withIdentifier: QuoteRowViewUIKit.reuseIdentifier,
          for: indexPath
        ) as? QuoteRowViewUIKit
      else {
        return UITableViewCell()
      }

      cell.configure(with: rowStore)
      return cell
    }
  }
}
