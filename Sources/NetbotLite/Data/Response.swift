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

@available(SwiftStdlib 6.0, *)
public struct Response: Codable, Hashable, Sendable {

  /// The HTTP response object if present. otherwise returns `nil`.
  public var httpResponse: HTTPResponse?

  /// The data is received as the message body of the response.
  public var body: Data?

  /// The HTTP message trailer headers (Trailer / chunked encoding).
  public var trailerHTTPFields: HTTPFields?

  package init(httpResponse: HTTPResponse) {
    self.httpResponse = httpResponse
  }

  package init() {}
}

@available(SwiftStdlib 6.0, *)
extension Response {

  /// Persistent model class.
  public typealias Model = V1._Response

  /// Create an instance of `Response` from persistent model.
  /// - Parameter persistentModel: Response persistent model.
  public init(persistentModel: Model) {
    httpResponse = persistentModel.httpResponse
    trailerHTTPFields = persistentModel.trailerHTTPFields
    body = persistentModel.body
  }
}
