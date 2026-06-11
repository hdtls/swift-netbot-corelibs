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

import Logging
import NIOCore
import NetbotLiteData

/// `ForwardProtocolReject` define protocol that reject all connections forwarded using this protocol.
@available(SwiftStdlib 6.0, *)
public struct ForwardProtocolReject: Equatable, Hashable, Sendable {

  public var name: String

  public init(name: String = "REJECT") {
    self.name = name
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocolReject: ForwardProtocol {

  public func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    throw AnalyzeError.connectionRefused
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocolReject: ForwardProtocolConvertible {}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocol where Self == ForwardProtocolReject {

  /// Return the default `ForwardProtocolReject`.
  public static var reject: ForwardProtocolReject {
    ForwardProtocolReject()
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocolConvertible where Self == ForwardProtocolReject {

  /// Return the default `ForwardProtocolReject`.
  public static var reject: ForwardProtocolReject {
    ForwardProtocolReject()
  }
}
