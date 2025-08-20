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
