//
//  TableViewRepresentable.swift
//  MiniReduxExample
//
//  Created by Bao Lei on 1/19/26.
//

import SwiftUI

struct HybridTableViewRepresentable: UIViewRepresentable {
  let store: TableStore

  func makeUIView(context: Context) -> QuotesTableView {
    QuotesTableView(store: store)
  }

  func updateUIView(_ uiView: QuotesTableView, context: Context) {}
}
