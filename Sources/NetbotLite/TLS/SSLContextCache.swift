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

// ===----------------------------------------------------------------------===//
//
// This source file is part of the AsyncHTTPClient open source project
//
// Copyright (c) 2021 Apple Inc. and the AsyncHTTPClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AsyncHTTPClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

@preconcurrency import Dispatch
import Logging
import NIOCore
import NIOSSL

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final public class SSLContextCache: Sendable {
  public static let shared: SSLContextCache = SSLContextCache()

  private let sslContextCache = LRUCache<BestEffortHashableTLSConfiguration, NIOSSLContext>(
    capacity: 8)
  private let offloadQueue = DispatchQueue(label: "anlzr-nio.SSLContextCache.offload.queue")
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension SSLContextCache {
  public func sslContext(
    configuration: NIOSSL.TLSConfiguration,
    eventLoop: any EventLoop,
    logger: Logger
  ) -> EventLoopFuture<NIOSSLContext> {
    let eqTLSConfiguration = BestEffortHashableTLSConfiguration(wrapping: configuration)
    let sslContext = self.sslContextCache.value(forKey: eqTLSConfiguration)

    if let sslContext = sslContext {
      logger.trace(
        "found SSL context in cache",
        metadata: ["tls-cfg": "\(configuration)"])
      return eventLoop.makeSucceededFuture(sslContext)
    }

    logger.trace(
      "creating new SSL context",
      metadata: ["tls-cfg": "\(configuration)"])
    let newSSLContext = self.offloadQueue.asyncWithFuture(eventLoop: eventLoop) {
      try NIOSSLContext(configuration: configuration)
    }

    newSSLContext.whenSuccess { (newSSLContext: NIOSSLContext) in
      self.sslContextCache.setValue(newSSLContext, forKey: eqTLSConfiguration)
    }

    return newSSLContext
  }

  public func syncSSLContext(
    configuration: NIOSSL.TLSConfiguration,
    logger: Logger
  ) throws -> NIOSSLContext {
    let eqTLSConfiguration = BestEffortHashableTLSConfiguration(wrapping: configuration)
    let sslContext = self.sslContextCache.value(forKey: eqTLSConfiguration)

    if let sslContext = sslContext {
      logger.trace(
        "found SSL context in cache",
        metadata: ["tls-cfg": "\(configuration)"])
      return sslContext
    }

    logger.trace(
      "creating new SSL context",
      metadata: ["tls-cfg": "\(configuration)"])
    let newSSLContext = try NIOSSLContext(configuration: configuration)

    self.sslContextCache.setValue(newSSLContext, forKey: eqTLSConfiguration)

    return newSSLContext
  }
}
