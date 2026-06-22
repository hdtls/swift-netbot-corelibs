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

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  /// A persistent representation of a ``Response``.
  ///
  /// `Response` stores the response metadata, body, and connection
  /// information in a format suitable for persistence.
  ///
  /// Use ``Response`` when working with responses in memory.
  /// Use ``V1/Response`` when storing response data.
  ///
  /// - SeeAlso: ``Response``
  @Model public class Response {

    /// The HTTP response head received from the server.
    ///
    /// Contains the status code, version, and response header fields.
    @Attribute(.transformable(by: SQLValueTransformer<HTTPResponse>.self))
    public var httpResponse: HTTPResponse?

    /// The trailing HTTP fields received after the response body.
    ///
    /// Trailer fields are commonly used with chunked transfer encoding
    /// to provide metadata that is only known after the body has been sent.
    @Attribute(.transformable(by: SQLValueTransformer<HTTPFields>.self))
    public var trailerHTTPFields: HTTPFields?

    /// The response body payload.
    ///
    /// This value contains the raw bytes received from the server.
    @Attribute(.externalStorage)
    public var body: Data?

    /// Information about the connection that produced the response.
    ///
    /// This value can be used to associate the response with a specific
    /// network connection and its recorded metadata.
    public var connection: V1.Connection?

    /// Creates an empty ``V1/Response`` record.
    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.Response {

  /// Converts a runtime ``Response`` into a persistent ``V1/Response`` snapshot.
  ///
  /// This method captures the current state of the response at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New `Response` to map.
  public func mergeValues(_ data: NetbotLiteData.Response) {
    #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
      if httpResponse != data.httpResponse {
        httpResponse = data.httpResponse
      }
      if trailerHTTPFields != data.trailerHTTPFields {
        trailerHTTPFields = data.trailerHTTPFields
      }
      if body != data.body {
        body = data.body
      }
    #else
      httpResponse = data.httpResponse
      trailerHTTPFields = data.trailerHTTPFields
      body = data.body
    #endif
  }
}
