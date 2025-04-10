//
// See LICENSE.txt for license information
//

import HTTPTypes

extension HTTPField: @retroactive Identifiable {
  public var id: String {
    String(describing: self)
  }
}
