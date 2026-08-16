import MiniRedux
import UIKit

final class QuotesTableViewUIKit: UIView {
  let store: QuotesTableStore

  private let activityIndicator = UIActivityIndicatorView(style: .medium)
  private let addButton = UIButton(type: .system)
  private let tableView: QuotesTableView

  init(store: QuotesTableStore) {
    self.store = store
    self.tableView = QuotesTableView(store: store)
    super.init(frame: .zero)
    setup()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateProperties() {
    super.updateProperties()
    if store.isLoading {
      activityIndicator.startAnimating()
    } else {
      activityIndicator.stopAnimating()
    }
  }

  private func setup() {
    backgroundColor = .systemBackground

    activityIndicator.hidesWhenStopped = true

    addButton.setTitle("Add a quote", for: .normal)
    addButton.addAction(UIAction { [weak self] _ in
      self?.store.send(.addTapped)
    }, for: .touchUpInside)

    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let header = UIStackView(arrangedSubviews: [activityIndicator, spacer, addButton])
    header.axis = .horizontal
    header.alignment = .center
    header.isLayoutMarginsRelativeArrangement = true
    header.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

    header.translatesAutoresizingMaskIntoConstraints = false
    tableView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(header)
    addSubview(tableView)

    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      header.leadingAnchor.constraint(equalTo: leadingAnchor),
      header.trailingAnchor.constraint(equalTo: trailingAnchor),

      tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
