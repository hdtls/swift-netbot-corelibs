//
// See LICENSE.txt for license information
//

@_exported public import AnlzrReports

extension Connection {

  public var `protocol`: String {
    guard let httpRequest = currentRequest.httpRequest else {
      return "TCP"
    }
    return (httpRequest.scheme ?? "TCP").uppercased()
  }
}
