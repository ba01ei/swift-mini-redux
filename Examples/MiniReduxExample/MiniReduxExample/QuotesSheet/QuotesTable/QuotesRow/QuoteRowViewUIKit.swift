import MiniRedux
import UIKit

final class QuoteRowViewUIKit: UITableViewCell {
  static let reuseIdentifier = "QuoteTableViewCell"
  
  private var store: QuoteRowStore?

  private let quoteLabel = UILabel()
  private let favoriteImageView = UIImageView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    quoteLabel.numberOfLines = 0
    quoteLabel.lineBreakMode = .byWordWrapping
    quoteLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(quoteLabel)
    favoriteImageView.contentMode = .scaleAspectFit
    favoriteImageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    accessoryView = favoriteImageView
    selectionStyle = .none
    addGestureRecognizer(UITapGestureRecognizer(
      target: self,
      action: #selector(handleTap)
    ))
    accessibilityHint = "Toggles favorite"
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
    let isFavorited = store?.isFavorited == true
    favoriteImageView.image = UIImage(systemName: isFavorited ? "star.fill" : "star")
    accessibilityValue = isFavorited ? "Favorited" : "Not favorited"
  }

  @objc private func handleTap() {
    store?.send(.cellTapped)
  }

  override func accessibilityActivate() -> Bool {
    store?.send(.cellTapped)
    return true
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    store = nil
    quoteLabel.text = nil
    accessibilityValue = nil
    setNeedsUpdateConfiguration()
  }
}
