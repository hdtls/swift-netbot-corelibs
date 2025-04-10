//
// See LICENSE.txt for license information
//

import AnlzrReports

extension Request {

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

    guard var path = httpRequest?.path, !path.isEmpty else {
      return "\(host)\(portString)"
    }

    path = path.hasPrefix("/") ? path : "/\(path)"
    path = path.last == "/" ? String(path.dropLast(1)) : path
    return "\(host)\(portString)\(path)"
  }

  public enum FormatStrategy {
    case head
    case body
  }

  public func formatted(strategy: FormatStrategy = .head) -> String {
    guard let httpRequest else {
      return ""
    }

    switch strategy {
    case .head:
      return """
        \(httpRequest.method) \(httpRequest.host(percentEncoded: false) ?? ""):\(httpRequest.port ?? 443) HTTP/1.1
        Host: \(httpRequest.host(percentEncoded: false) ?? "")
        \(httpRequest.headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
        """
    case .body:
      guard let body else {
        return "No Data".localizedCapitalized
      }
      return String(data: body, encoding: .utf8) ?? "No Data".localizedCapitalized
    }
  }
}
