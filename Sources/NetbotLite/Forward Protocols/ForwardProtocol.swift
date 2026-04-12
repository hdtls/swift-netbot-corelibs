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

import Logging
import NIOCore
import NetbotLiteData

/// Types that conform to the `ForwardProtocolConvertible` protocol can provide
/// their own representation to be used when converting an instance to a `ForwardProtocol`.
@available(SwiftStdlib 5.3, *)
public protocol ForwardProtocolConvertible: Sendable {

  /// Converting an instance of conforming type to `ForwardProtocol`.
  func asForwardProtocol() -> any ForwardProtocol
}

/// A `ForwardProtocol` declares the programmatic interface for an object that provides a tunnel.
@available(SwiftStdlib 5.3, *)
public protocol ForwardProtocol: Sendable {

  /// The name of the provider.
  var name: String { get }

  /// Creates a new connection for specified target.
  ///
  /// - Parameters:
  ///   - logger: The `Logger` that will be used to log messages.
  ///   - connection: The `Connection` contains target meta data.
  ///   - eventLoop: The `EventLoop` whitch is used by this `ForwardProtocol` for execution.
  /// - Returns: The connected channel.
  func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws
    -> any Channel
}

/// A `ProxiableForwardProtocol` declares the programmatic interface for an object that provides a proxy tunnel.
@available(SwiftStdlib 5.3, *)
public protocol ProxiableForwardProtocol: ForwardProtocol {

  /// Address of the proxy server.
  var serverAddress: String { get }

  /// Port of the proxy server.
  var port: Int { get }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolConvertible where Self: ForwardProtocol {

  public func asForwardProtocol() -> any ForwardProtocol {
    self
  }
}
