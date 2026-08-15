import UIKit

final class QuoteRowView: UITableViewCell {
  static let reuseIdentifier = "QuoteTableViewCell"
  
  private var store: QuoteRowStore?

  let quoteLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    quoteLabel.numberOfLines = 0
    quoteLabel.lineBreakMode = .byWordWrapping
    quoteLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(quoteLabel)
    NSLayoutConstraint.activate([
      quoteLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
      quoteLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
      quoteLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
      quoteLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with store: QuoteRowStore) {
    if let currentStore = self.store, currentStore === store {
      return
    }
    self.store = store
    setNeedsUpdateConfiguration()
  }

  override func updateConfiguration(using state: UICellConfigurationState) {
    super.updateConfiguration(using: state)
    quoteLabel.text = store?.text
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    store = nil
    quoteLabel.text = nil
  }
}
