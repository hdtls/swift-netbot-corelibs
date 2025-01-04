//
// See LICENSE.txt for license information
//

import SwiftUI

extension View {

  @preconcurrency func onSizeChange(perform: @escaping @Sendable (CGSize) -> Void) -> some View {
    background(
      GeometryReader { g in
        Color.clear
          .preference(key: SizePreferenceKey.self, value: g.size)
      }
    )
    .onPreferenceChange(SizePreferenceKey.self, perform: perform)
  }
}

private struct SizePreferenceKey: PreferenceKey {
  static let defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
