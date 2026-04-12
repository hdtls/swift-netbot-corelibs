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
import NIOHTTP1
import NIOHTTPCompression
import NIOSSL
import NetbotLiteData

@available(SwiftStdlib 5.3, *)
extension Channel {

  func configureTLSMitMPipeline(
    logger: Logger,
    connection: Connection,
    decryptionDNSNames: [String],
    decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle
  ) -> EventLoopFuture<Void> {
    if eventLoop.inEventLoop {
      return eventLoop.makeCompletedFuture {
        try _syncConfigureTLSMitMPipeline(
          logger: logger,
          connection: connection,
          decryptionDNSNames: decryptionDNSNames,
          decryptionSSLPKCS12Bundle: decryptionSSLPKCS12Bundle
        )
      }
    } else {
      return eventLoop.submit {
        try self._syncConfigureTLSMitMPipeline(
          logger: logger,
          connection: connection,
          decryptionDNSNames: decryptionDNSNames,
          decryptionSSLPKCS12Bundle: decryptionSSLPKCS12Bundle
        )
      }
    }
  }

  func configureTLSMitMPipeline(
    logger: Logger,
    connection: Connection,
    decryptionDNSNames: [String]
  ) -> EventLoopFuture<Void> {
    if eventLoop.inEventLoop {
      return eventLoop.makeCompletedFuture {
        try _syncConfigureTLSMitMPipeline(
          logger: logger,
          connection: connection,
          decryptionDNSNames: decryptionDNSNames,
          decryptionSSLPKCS12Bundle: nil
        )
      }
    } else {
      return eventLoop.submit {
        try self._syncConfigureTLSMitMPipeline(
          logger: logger,
          connection: connection,
          decryptionDNSNames: decryptionDNSNames,
          decryptionSSLPKCS12Bundle: nil
        )
      }
    }
  }

  /// Configure TLS MitM pipeline if needed.
  ///
  /// If `serverSSLCertificateCache` does not contains certificates and privateKeys pair, configure will be ignored.
  private func _syncConfigureTLSMitMPipeline(
    logger: Logger,
    connection: Connection,
    decryptionDNSNames: [String],
    decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle?
  ) throws {
    eventLoop.assertInEventLoop()

    guard let host = connection.originalRequest?.host(percentEncoded: false) else {
      return
    }
    let decryptionRequired = decryptionDNSNames.contains {
      guard $0.hasPrefix("*.") else {
        return host == $0
      }
      return host.hasSuffix(String($0.dropFirst()))
    }
    guard decryptionRequired else {
      return
    }

    if let decryptionSSLPKCS12Bundle {
      let configuration = NIOSSL.TLSConfiguration.makeServerConfiguration(
        certificateChain: decryptionSSLPKCS12Bundle.certificateChain.map { .certificate($0) },
        privateKey: .privateKey(decryptionSSLPKCS12Bundle.privateKey)
      )
      // Set up server channel pipeline to decrypt HTTPS stream.
      let context = try SSLContextCache.shared.syncSSLContext(
        configuration: configuration,
        logger: logger
      )
      let handler = NIOSSLServerHandler(context: context)

      try pipeline.syncOperations.addHandler(handler)
    } else {
      // Because we have decrypted HTTPS stream, so we need set up client channel to encode decrypted
      // plain HTTP request to HTTPS request.
      let configuration = NIOSSL.TLSConfiguration.makeClientConfiguration()
      let context = try SSLContextCache.shared.syncSSLContext(
        configuration: configuration,
        logger: logger
      )
      let handler = try NIOSSLClientHandler(context: context, serverHostname: host)

      try pipeline.syncOperations.addHandler(handler)
    }
  }
}
