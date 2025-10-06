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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// An URL rewrite representation object, define how to navigates the user from a source URL to a target URL with
/// a specific HTTP status code.
@available(SwiftStdlib 5.3, *)
public struct URLRewrite: Equatable, Hashable, Sendable {

  /// A boolean value determinse whether this rule is enabled or disabled.
  public var isEnabled = true

  /// A redirection type representation object, define type of URLRewrite.
  public enum RewriteType: String, CaseIterable, Codable, Hashable, Sendable {
    /// Rewrite HTTP fields.
    case httpFields = "http-fields"

    /// Redirect with HTTP 302.
    case found

    /// Redirect with HTTP 307
    case temporaryRedirect = "temporary-redirect"

    /// Reject this connection.
    case reject

    /// Localized name of this redirection.
    public var localizedName: String {
      switch self {
      case .httpFields:
        return "HTTP Fields"
      case .found:
        return "HTTP 302"
      case .temporaryRedirect:
        return "HTTP 307"
      case .reject:
        return "Reject"
      }
    }
  }

  /// Response status for this redirection.
  public var type = RewriteType.found

  /// Incoming request URL matching pattern.
  public var pattern = ""

  /// URL redirect destination.
  public var destination = ""

  /// The time the resource was created.
  public var creationDate: Date

  /// Create an `URLRewrite` with specified values.
  public init(
    isEnabled: Bool = true,
    type: RewriteType = .found,
    pattern: String = "",
    destination: String = ""
  ) {
    self.isEnabled = isEnabled
    self.type = type
    self.pattern = pattern
    self.destination = destination
    if #available(SwiftStdlib 5.5, *) {
      self.creationDate = .now
    } else {
      self.creationDate = .init()
    }
  }
}
