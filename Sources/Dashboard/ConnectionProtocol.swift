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
