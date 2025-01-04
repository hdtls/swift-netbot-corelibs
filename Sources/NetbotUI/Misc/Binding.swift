//
// See LICENSE.txt for license information
//

public import SwiftUI

extension Binding where Value == Bool {

  public var reverse: Binding<Bool> {
    .init {
      !wrappedValue
    } set: {
      wrappedValue = !$0
    }
  }
}
