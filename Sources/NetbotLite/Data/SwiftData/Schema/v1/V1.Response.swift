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
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    @Model final public class _Response {

      /// The HTTP request object if present. otherwise returns `nil`.
      @Attribute(.transformable(by: SQLValueTransformer<HTTPResponse>.self))
      public var httpResponse: HTTPResponse?

      /// The HTTP message trailer headers (Trailer / chunked encoding).
      @Attribute(.transformable(by: SQLValueTransformer<HTTPFields>.self))
      public var trailers: HTTPFields?

      /// The data is sent as the message body of the request.
      @Attribute(.externalStorage)
      public var body: Data?

      public init() {}
    }
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class _Response {

      /// The HTTP request object if present. otherwise returns `nil`.
      public var httpResponse: HTTPResponse?

      /// The HTTP message trailer headers (Trailer / chunked encoding).
      public var trailers: HTTPFields?

      /// The data is sent as the message body of the request.
      public var body: Data?

      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1._Response {

  /// Merge new values from DTO.
  /// - Parameter data: New `Response` to merge.
  public func mergeValues(_ data: Response) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      httpResponse = data.httpResponse
      trailers = data.trailers
      body = data.body
    #else
      if httpResponse != data.httpResponse {
        httpResponse = data.httpResponse
      }
      if trailers != data.trailers {
        trailers = data.trailers
      }
      if body != data.body {
        body = data.body
      }
    #endif
  }
}
