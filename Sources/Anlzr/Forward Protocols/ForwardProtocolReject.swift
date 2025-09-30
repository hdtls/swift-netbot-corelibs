//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import AnlzrReports
import Logging
import NIOCore

/// `ForwardProtocolReject` define protocol that reject all connections forwarded using this protocol.
@available(SwiftStdlib 5.3, *)
public struct ForwardProtocolReject: Equatable, Hashable, Sendable {

  public var name: String

  public init(name: String = "REJECT") {
    self.name = name
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolReject: ForwardProtocol {

  public func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    throw AnlzrError.connectionRefused
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolReject: ForwardProtocolConvertible {}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocol where Self == ForwardProtocolReject {

  /// Return the default `ForwardProtocolReject`.
  public static var reject: ForwardProtocolReject {
    ForwardProtocolReject()
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolConvertible where Self == ForwardProtocolReject {

  /// Return the default `ForwardProtocolReject`.
  public static var reject: ForwardProtocolReject {
    ForwardProtocolReject()
  }
}
