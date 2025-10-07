//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AnlzrReports
import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationInternationalization
#else
  import Foundation
#endif

@available(SwiftStdlib 5.9, *)
extension Connection.PersistentModel {

  /// Pretty printed forwarding policy.
  public var forwardingPolicy: String {
    "\(forwardingReport?.forwardProtocol ?? "FINAL") (\(forwardingReport?.forwardingRule ?? "*"))"
  }

  public var maximumUploadBandwidthString: String { "" }

  public var maximumDowloadBandwidthString: String { "" }

  /// The name of the application layer protocol if available or transport layer protocol.
  public var protocolName: String {
    guard let httpRequest = currentRequest?.httpRequest else {
      return "TCP"
    }
    return (httpRequest.scheme ?? "TCP").uppercased()
  }

  /// A boolean value determinse whether the connection is in an active state.
  ///
  /// Please note both `establising` and `active` is consider active.
  public var isActive: Bool { state == .establishing || state == .active }
}

@available(SwiftStdlib 5.3, *)
extension Data {
  public func formatted() -> String {
    String(data: self, encoding: .utf8) ?? "No Data".localizedCapitalized
  }
}

@available(SwiftStdlib 5.3, *)
extension HTTPRequest {
  public func formatted() -> String {
    """
    \(method) \(host(percentEncoded: false) ?? ""):\(port ?? 443) HTTP/1.1
    Host: \(host(percentEncoded: false) ?? "")
    \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
    """
  }
}

@available(SwiftStdlib 5.3, *)
extension HTTPResponse {
  public func formatted() -> String {
    """
    HTTP/1.1 \(status)
    \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
    """
  }
}

@available(SwiftStdlib 5.9, *)
extension Response.PersistentModel {

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
