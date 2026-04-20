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

import Logging
import NIOCore
import NetbotLiteData

/// `ForwardProtocolReject` define protocol that reject all connections forwarded using this protocol.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct ForwardProtocolReject: Equatable, Hashable, Sendable {

  public var name: String

  public init(name: String = "REJECT") {
    self.name = name
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocolReject: ForwardProtocol {

  public func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    throw AnalyzeError.connectionRefused
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocolReject: ForwardProtocolConvertible {}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocol where Self == ForwardProtocolReject {

  /// Return the default `ForwardProtocolReject`.
  public static var reject: ForwardProtocolReject {
    ForwardProtocolReject()
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocolConvertible where Self == ForwardProtocolReject {

  /// Return the default `ForwardProtocolReject`.
  public static var reject: ForwardProtocolReject {
    ForwardProtocolReject()
  }
}
