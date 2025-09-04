//
// See LICENSE.txt for license information
//

import HTTPTypes

@available(SwiftStdlib 5.3, *)
extension HTTPField: @retroactive Identifiable {
  public var id: String {
    String(describing: self)
  }
}
