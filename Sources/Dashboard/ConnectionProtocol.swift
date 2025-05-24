//
// See LICENSE.txt for license information
//

import AnlzrReports
import HTTPTypes

extension Connection {

  public var `protocol`: String {
    guard let httpRequest = currentRequest.httpRequest else {
      return "TCP"
    }
    return (httpRequest.scheme ?? "TCP").uppercased()
  }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Connection.PersistentModel {

  public var `protocol`: String {
    guard let httpRequest = _currentRequest?.httpRequest else {
      return "TCP"
    }
    return (httpRequest.scheme ?? "TCP").uppercased()
  }
}
