// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import HTTPTypes
import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
extension Connection.Model {

  /// Pretty printed forwarding policy.
  public var forwardProtocolFormatted: String {
    guard let `protocol` = forwardingReport?.forwardProtocol else { return "" }
    guard let rule = forwardingReport?.forwardingRule else {
      return "\(`protocol`) (*)"
    }
    return "\(`protocol`) (\(rule))"
  }

  public var maximumUploadBandwidthString: String { "" }

  public var maximumDowloadBandwidthString: String { "" }

  /// The name of the application layer protocol if available or transport layer protocol.
  public var protocolName: String {
    guard let httpRequest = currentRequest?.httpRequest else {
      return "TCP"
    }
    return (httpRequest.scheme ?? "HTTP").uppercased()
  }

  /// A boolean value determinse whether the connection is in an active state.
  ///
  /// Please note both `establising` and `active` is consider active.
  public var isActive: Bool { state == .establishing || state == .active }
}

@available(SwiftStdlib 6.0, *)
extension Data {
  public func formatted() -> String {
    guard !isEmpty else { return "No Data".localizedCapitalized }
    return String(data: self, encoding: .utf8) ?? "No Data".localizedCapitalized
  }
}

@available(SwiftStdlib 6.0, *)
extension HTTPRequest {
  public func formatted() -> String {
    """
    \(method) \(host(percentEncoded: false) ?? ""):\(port ?? 443) HTTP/1.1
    Host: \(host(percentEncoded: false) ?? "")
    \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
    """
  }
}

@available(SwiftStdlib 6.0, *)
extension HTTPResponse {
  public func formatted() -> String {
    """
    HTTP/1.1 \(status)
    \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
    """
  }
}

@available(SwiftStdlib 6.0, *)
extension Response.Model {

  public var isImage: Bool {
    httpResponse?.headerFields[.contentType]?.hasPrefix("image") ?? false
  }

  public var isText: Bool {
    httpResponse?.headerFields[.contentType]?.hasPrefix("text") ?? false
  }

  public var isForm: Bool {
    let possibleValues = ["application/x-www-form-urlencoded", "multipart/form-data"]
    return possibleValues.contains(httpResponse?.headerFields[.contentType] ?? "")
  }

  public var isJSON: Bool {
    httpResponse?.headerFields[.contentType]?.hasSuffix("json") ?? false
  }
}
