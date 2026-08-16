//
//  SwiftUIQuoteRowView.swift
//  MiniReduxExample
//
//  Created by Bao Lei on 8/15/26.
//

import SwiftUI
import MiniRedux

struct QuoteRowViewSwiftUI: View {
  let store: QuoteRowStore
  
  var body: some View {
    HStack {
      Text(store.text)
      Spacer()
      Image(systemName: store.isFavorited ? "star.fill" : "star")
    }
    .onTapGesture {
      store.send(.cellTapped)
    }
  }
}
