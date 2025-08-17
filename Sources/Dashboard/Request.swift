//
// See LICENSE.txt for license information
//

import AnlzrReports
import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

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

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension V1._Request {

  /// Returns the host component of the Request if present, otherwise returns `nil`.
  ///
  /// - Parameter percentEncoded: Whether the host should be percent encoded,
  ///   defaults to `true`.
  /// - Returns: The host component of the Request
  public func host(percentEncoded: Bool = true) -> String? {
    guard let host = address?.host(percentEncoded: percentEncoded) else {
      return httpRequest?.host(percentEncoded: percentEncoded)
    }
    return host
  }

  /// Returns the port component of the Request if present, otherwise returns `nil`.
  public var port: Int? {
    guard let port = address?.port else {
      return httpRequest?.port
    }
    return port
  }

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
}
