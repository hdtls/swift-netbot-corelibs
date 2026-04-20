// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

@_exported import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// A stubbed HTTP response representation object, define how to stub response for request.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct StubbedHTTPResponse: Equatable, Hashable, Sendable {

  /// A boolean value determinse whether this rule is enabled or disabled.
  public var isEnabled = true

  /// Incoming request URL matching pattern.
  public var pattern: String = ""

  /// Response body content URL.
  public var bodyContentsURL: URL?

  /// Response status.
  public var status: HTTPResponse.Status = .ok

  /// Additional HTTP fields for stubbed response.
  public var additionalHTTPFields: HTTPFields = HTTPFields()

  /// The time the resource was created.
  public var creationDate: Date

  /// Create a `StubbedHTTPResponse` with specified values.
  public init(
    isEnabled: Bool = true,
    pattern: String = "",
    bodyContentsURL: URL? = nil,
    status: HTTPResponse.Status = .ok,
    additionalHTTPFields: HTTPFields = HTTPFields()
  ) {
    self.isEnabled = isEnabled
    self.pattern = pattern
    self.bodyContentsURL = bodyContentsURL
    self.status = status
    self.additionalHTTPFields = additionalHTTPFields
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      self.creationDate = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
    #else
      self.creationDate = .now
    #endif
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension StubbedHTTPResponse {

  public typealias Model = V1._StubbedHTTPResponse

  public init(persistentModel: Model) {
    self.init()
    isEnabled = persistentModel.isEnabled
    pattern = persistentModel.pattern
    bodyContentsURL = persistentModel.bodyContentsURL
    status = .init(
      code: persistentModel.statusCode,
      reasonPhrase: persistentModel.reasonPhrase
    )
    additionalHTTPFields = persistentModel.additionalHTTPFields
    creationDate = persistentModel.creationDate
  }
}
