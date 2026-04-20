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

// ===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NIOConcurrencyHelpers
import NIOCore

/// A protocol that covers an object that does DNS lookups.
///
/// In general the rules for the resolver are relatively broad: there are no specific requirements on how
/// it operates. However, the rest of the code assumes that it obeys RFC 6724, particularly section 6 on
/// ordering returned addresses. That is, the IPv6 and IPv4 responses should be ordered by the destination
/// address ordering rules from that RFC. This specification is widely implemented by getaddrinfo
/// implementations, so any implementation based on getaddrinfo will work just fine. In the future, a custom
/// resolver will need also to implement these sorting rules.
///
/// - SeeAlso: NIOPosix.Resolver for more informations.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public protocol Resolver: Sendable {

  func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]>

  func initiateAAAAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]>

  func cancelQueries()
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
struct DefaultResolver: Resolver, Sendable {
  let eventLoop: any EventLoop

  func initiateAQuery(host: String, port: Int) -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]> {
    eventLoop.makeSucceededFuture([])
  }

  func initiateAAAAQuery(host: String, port: Int)
    -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
  {
    eventLoop.makeSucceededFuture([])
  }

  func cancelQueries() {
  }
}
