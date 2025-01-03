//
// See LICENSE.txt for license information
//

@_exported public import HTTPTypes

extension HTTPField: @retroactive Identifiable {
  public var id: String {
    String(describing: self)
  }
}
