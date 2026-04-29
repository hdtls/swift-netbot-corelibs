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

import HTTPTypes

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension AnyProxy {

  /// WebSocket settings for VMESS protocol.
  public struct WebSocket: Codable, Hashable, Sendable {

    /// A boolean value determine whether WebSocket should be enabled.
    public var isEnabled: Bool = false

    /// The URL path of WebSocket request.
    public var uri: String = "/"

    /// Addition HTTP fields of WebSocket request.
    public var additionalHTTPFields: HTTPFields?

    /// Initialize an instance of `WebSocket` settings with specified parameters.
    public init(isEnabled: Bool = false, uri: String = "/", additionalHTTPFields: HTTPFields? = nil)
    {
      self.isEnabled = isEnabled
      self.uri = uri
      self.additionalHTTPFields = additionalHTTPFields
    }
  }
}
