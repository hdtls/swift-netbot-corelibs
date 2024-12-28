//
// See LICENSE.txt for license information
//

@_exported public import AnlzrReports

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Request {

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  public func url() -> String {
    guard let host = host(percentEncoded: false) else {
      return ""
    }

    var portString = ""
    if let port {
      if port != 80 && port != 443 {
        portString = ":\(port)"
      }
    }

    guard let path = httpRequest?.path, !path.isEmpty else {
      return "\(host)\(portString)"
    }

    return "\(host)\(portString)/\(path.trimmingPrefix("/"))"
  }

  public func formatted() -> String {
    guard let httpRequest else {
      return ""
    }
    return """
      \(httpRequest.method) \(httpRequest.host(percentEncoded: false) ?? ""):\(httpRequest.port ?? 443) HTTP/1.1
      Host: \(httpRequest.host(percentEncoded: false) ?? "")
      \(httpRequest.headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
      """
  }
}
