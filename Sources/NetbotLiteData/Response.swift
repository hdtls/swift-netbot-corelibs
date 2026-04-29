// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct Response: Codable, Hashable, Sendable {

  /// The HTTP response object if present. otherwise returns `nil`.
  public var httpResponse: HTTPResponse?

  /// The data is received as the message body of the response.
  public var body: Data?

  public init(httpResponse: HTTPResponse) {
    self.httpResponse = httpResponse
  }

  public init() {}
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Response {

  public typealias Model = V1._Response

  public init(persistentModel: Model) {
    httpResponse = persistentModel.httpResponse
    body = persistentModel.body
  }
}
