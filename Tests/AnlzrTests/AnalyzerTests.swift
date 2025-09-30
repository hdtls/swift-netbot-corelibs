//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import Logging
import NIOCore
import NIOSSL
import Testing

@testable import Anlzr

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite struct AnalyzerTests {

  var decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle {
    let base64EncodedNoPassP12 = """
          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
      """
    return try! NIOSSLPKCS12Bundle(
      buffer: Array(Data(base64Encoded: base64EncodedNoPassP12, options: .ignoreUnknownCharacters)!)
    )
  }

  @Test func initializer() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))
    #expect(bot.webProxyListenAddress == (try! SocketAddress(ipAddress: "127.0.0.1", port: 6152)))
    #expect(
      bot.socksProxyListenAddress == (try! SocketAddress(ipAddress: "127.0.0.1", port: 6153))
    )
    #expect(bot.outboundMode == .direct)
    #expect(bot.forwardProtocol.asForwardProtocol().name == "DIRECT")
    #expect(bot.forwardingRules.isEmpty)
    #expect(bot.capabilities.isEmpty)
    #expect(bot.decryptionDNSNames.isEmpty)
    #expect(bot.decryptionSSLPKCS12Bundle == nil)
    #expect(!bot.isActive)
  }

  @Test func setOutboundMode() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))
    await bot.setOutboundMode(.ruleBased)
    #expect(bot.outboundMode == .ruleBased)
  }

  @Test func setForwardingProtocol() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))
    await bot.setForwardProtocol(.reject)
    #expect(bot.forwardProtocol.asForwardProtocol().name == "REJECT")
  }

  @Test func setForwardingRules() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))
    await bot.setForwardingRules([_FinalForwardingRule()])
    #expect(bot.forwardingRules.count == 1)
  }

  @Test func setEnabledHTTPCapabilities() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))
    await bot.setEnabledHTTPCapabilities(.httpsDecryption)
    #expect(bot.capabilities == .httpsDecryption)
  }

  @Test func setDecryptionSSLPKCS12Bundle() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))

    await bot.setDecryptionSSLPKCS12Bundle(decryptionSSLPKCS12Bundle)
    #expect(bot.decryptionDNSNames == ["example.com", "*.example.com"])
    #expect(bot.decryptionSSLPKCS12Bundle == decryptionSSLPKCS12Bundle)
  }

  @Test func preventSetSameDecryptionSSLPKCS12Bundle() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))

    await bot.setDecryptionSSLPKCS12Bundle(decryptionSSLPKCS12Bundle)
    await bot.setDecryptionSSLPKCS12Bundle(decryptionSSLPKCS12Bundle)
    #expect(bot.decryptionDNSNames == ["example.com", "*.example.com"])
    #expect(bot.decryptionSSLPKCS12Bundle == decryptionSSLPKCS12Bundle)
  }

  @Test func setDecryptionSSLPKCS12BundleToNil() async throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bot = Analyzer(group: group, logger: .init(label: ""))

    await bot.setDecryptionSSLPKCS12Bundle(decryptionSSLPKCS12Bundle)
    #expect(bot.decryptionDNSNames == ["example.com", "*.example.com"])
    #expect(bot.decryptionSSLPKCS12Bundle == decryptionSSLPKCS12Bundle)

    await bot.setDecryptionSSLPKCS12Bundle(nil)
    #expect(bot.decryptionDNSNames.isEmpty)
    #expect(bot.decryptionSSLPKCS12Bundle == nil)
  }
}
