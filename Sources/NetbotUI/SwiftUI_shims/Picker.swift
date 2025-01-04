//
// See LICENSE.txt for license information
//

public import SwiftUI

extension Picker where Label == EmptyView {

  /// Creates a picker without label.
  ///
  /// - Parameters:
  ///     - selection: A binding to a property that determines the
  ///       currently-selected option.
  ///     - content: A view that contains the set of options.
  public init(selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
    self.init(selection: selection, content: content) {
      EmptyView()
    }
  }
}
