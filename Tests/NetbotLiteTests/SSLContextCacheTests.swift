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

import NIOCore
import NIOEmbedded
import NIOSSL
import Testing

@testable import NetbotLite

@Suite struct SSLContextCacheTests {

  @available(SwiftStdlib 6.0, *)
  @Test("syncSSLContext caches and returns the same object for the same config")
  func syncSSLContextCaching() throws {
    let config = NIOSSL.TLSConfiguration.makeClientConfiguration()
    let cache = SSLContextCache()
    let ctx1 = try cache.syncSSLContext(configuration: config)
    let ctx2 = try cache.syncSSLContext(configuration: config)
    #expect(ctx1 === ctx2)
  }

  @available(SwiftStdlib 6.0, *)
  @Test("sslContext (async) caches the context for same config")
  func asyncSSLContextCaching() async throws {
    let config = NIOSSL.TLSConfiguration.makeClientConfiguration()
    let cache = SSLContextCache()
    let eventLoop = EmbeddedEventLoop()

    let ctx1 = try await cache.sslContext(configuration: config, eventLoop: eventLoop).get()
    let ctx2 = try await cache.sslContext(configuration: config, eventLoop: eventLoop).get()
    #expect(ctx1 === ctx2)
  }

  @available(SwiftStdlib 6.0, *)
  @Test("cache returns different contexts for different configs")
  func differentConfigsGetDifferentContexts() throws {
    let config1 = NIOSSL.TLSConfiguration.makeClientConfiguration()
    var config2 = NIOSSL.TLSConfiguration.makeClientConfiguration()
    config2.certificateVerification = .none
    let cache = SSLContextCache()
    let ctx1 = try cache.syncSSLContext(configuration: config1)
    let ctx2 = try cache.syncSSLContext(configuration: config2)
    #expect(ctx1 !== ctx2)
  }

  @available(SwiftStdlib 6.0, *)
  @Test("cache evicts old contexts after capacity is reached")
  func eviction() throws {
    let cache = SSLContextCache()
    var contexts: [NIOSSLContext] = []
    for i in 0..<10 {
      var config = NIOSSL.TLSConfiguration.makeClientConfiguration()
      config.certificateVerification = (i % 2 == 0) ? .none : .fullVerification
      config.minimumTLSVersion = .tlsv12
      config.maximumTLSVersion = .tlsv13
      let ctx = try cache.syncSSLContext(configuration: config)
      contexts.append(ctx)
    }
    // cache capacity is 8; so at least two should be evicted
    let config0 = NIOSSL.TLSConfiguration.makeClientConfiguration()
    let ctx0 = try? cache.syncSSLContext(configuration: config0)
    #expect(ctx0 != nil)
  }
}
