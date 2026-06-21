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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// A in-memory representation of a response.
///
/// ``Response`` stores the response metadata, body, and connection
/// information in a format suitable for persistence.
///
/// Use ``Response`` when working with responses in memory.
/// Use ``V1/Response`` when storing response data.
///
/// - SeeAlso: ``V1/Response``
@available(SwiftStdlib 6.0, *)
public struct Response: Codable, Hashable, Sendable {

  /// The HTTP response head received from the server.
  ///
  /// Contains the status code, version, and response header fields.
  public var httpResponse: HTTPResponse?

  /// The response body payload.
  ///
  /// This value contains the raw bytes received from the server.
  public var body: Data?

  /// The trailing HTTP fields received after the response body.
  ///
  /// Trailer fields are commonly used with chunked transfer encoding
  /// to provide metadata that is only known after the body has been sent.
  public var trailerHTTPFields: HTTPFields?

  /// Create an instance of an HTTP associated ``Response``.
  /// - Parameter httpResponse: Associated raw HTTP response.
  package init(httpResponse: HTTPResponse) {
    self.httpResponse = httpResponse
  }

  /// Create an empty ``Response``.
  package init() {}
}

@available(SwiftStdlib 6.0, *)
extension Response {

  /// In used persistent model typealias.
  public typealias Model = V1.Response

  /// Create a new ``Response`` from persistent response.
  /// - Parameter persistentModel: Persistent response.
  public init(persistentModel: Model) {
    httpResponse = persistentModel.httpResponse
    trailerHTTPFields = persistentModel.trailerHTTPFields
    body = persistentModel.body
  }
}
