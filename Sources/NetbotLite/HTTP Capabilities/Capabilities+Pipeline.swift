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
import NIOHTTP1
import NIOHTTPCompression
import NIOSSL
import NetbotLiteData

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension CapabilityFlags {

  func buildTLS(
    logger: Logger,
    application: AnalyzeBot,
    connection session: Connection,
    decryptionDNSNames: [String],
    decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle?,
    inputStream: any Channel,
    outputStream: any Channel
  ) {
    inputStream.eventLoop.assertInEventLoop()
    try? inputStream.pipeline.syncOperations.addHandler(
      Recognizer.Handler<Recognizer.TLS> { result in
        var mayBeTLS = false
        if case .identified(let proto) = result {
          mayBeTLS = proto == "TLS"
        }
        session.tls = mayBeTLS

        // To continue the TLS decryption pipeline setup, we need to confirm that the
        // current session contains a clear host name and is transmitted through TLS.
        // At the same time, we must ensure that https decryption has been enabled and
        // the relevant certificates used for decryption are valid.
        guard mayBeTLS,
          contains(.httpsDecryption),
          let decryptionSSLPKCS12Bundle,
          let host = session.originalRequest?.host(percentEncoded: false)
        else {
          return inputStream.eventLoop.makeSucceededVoidFuture()
        }

        // Check whether the hostname should support TLS decryption.
        let decryptionRequired = decryptionDNSNames.contains {
          guard $0.hasPrefix("*.") else { return host == $0 }
          return host.hasSuffix(String($0.dropFirst()))
        }
        guard decryptionRequired else {
          return inputStream.eventLoop.makeSucceededVoidFuture()
        }

        return EventLoopFuture.andAllComplete(
          [
            SSLContextCache.shared.sslContext(
              configuration: .makeServerConfiguration(
                certificateChain: decryptionSSLPKCS12Bundle.certificateChain.map {
                  .certificate($0)
                },
                privateKey: .privateKey(decryptionSSLPKCS12Bundle.privateKey)
              ),
              eventLoop: inputStream.eventLoop,
              logger: logger
            )
            .flatMap { sslContext in
              inputStream.eventLoop.makeCompletedFuture {
                let position = try inputStream.pipeline.syncOperations.context(
                  name: Recognizer.TLS.name
                ).handler
                try inputStream.pipeline.syncOperations.addHandler(
                  NIOSSLServerHandler(context: sslContext), position: .after(position)
                )
              }
            },

            // Because we have decrypted HTTPS stream, so we need set up client channel to encode decrypted
            // plain HTTP request to HTTPS request.
            SSLContextCache.shared.sslContext(
              configuration: .makeClientConfiguration(),
              eventLoop: outputStream.eventLoop,
              logger: logger
            )
            .flatMap { sslContext in
              outputStream.eventLoop.makeCompletedFuture {
                let handler = try NIOSSLClientHandler(
                  context: sslContext, serverHostname: host)
                try outputStream.pipeline.syncOperations.addHandler(handler)
              }
            },
          ], on: inputStream.eventLoop)
      },
      name: Recognizer.TLS.name
    )
  }

  func buildHTTP(
    logger: Logger,
    connection session: Connection,
    inMemoryHTTPCaptureFilters: [String],
    onDiskHTTPCaptureFilters: [String],
    inputStream: any Channel,
    outputStream: any Channel
  ) {
    inputStream.eventLoop.assertInEventLoop()
    try? inputStream.pipeline.syncOperations.addHandler(
      Recognizer.Handler<Recognizer.HTTP> { result in
        var mayBeHTTP = false
        if case .identified(let proto) = result {
          mayBeHTTP = proto == "HTTP"
        }

        // Try to setup TLS decryption if current connection is over TLS and enabled
        // capabilities contains httpsDecryption.
        guard mayBeHTTP,
          contains(.httpCapture) || contains(.rewrite)
        else { return inputStream.eventLoop.makeSucceededVoidFuture() }

        return EventLoopFuture.andAllComplete(
          [
            inputStream.eventLoop.makeCompletedFuture {
              let position = try inputStream.pipeline.syncOperations.context(
                name: Recognizer.HTTP.name
              ).handler

              try inputStream.pipeline.syncOperations.addHandlers(
                [
                  HTTPResponseEncoder(),
                  ByteToMessageHandler(HTTPRequestDecoder()),
                  HTTPResponseCompressor(),
                  __CapabilitiesProcessingHandler<HTTPRequestHead>(
                    connection: session,
                    enabledHTTPCapabilities: self
                  ),
                  InMemoryHTTPCapature<HTTPRequestHead>(
                    connection: session,
                    captureFilters: inMemoryHTTPCaptureFilters
                  ),
                  OnDiskHTTPCapature<HTTPRequestHead>(
                    connection: session,
                    captureFilters: onDiskHTTPCaptureFilters
                  ),
                ],
                position: .after(position)
              )
            },

            outputStream.eventLoop.makeCompletedFuture {
              try outputStream.pipeline.syncOperations.addHandlers(
                [
                  HTTPRequestEncoder(),
                  ByteToMessageHandler(HTTPResponseDecoder()),
                  NIOHTTPResponseDecompressor(limit: .none),
                  __CapabilitiesProcessingHandler<HTTPResponseHead>(
                    connection: session,
                    enabledHTTPCapabilities: self
                  ),
                  InMemoryHTTPCapature<HTTPResponseHead>(
                    connection: session,
                    captureFilters: inMemoryHTTPCaptureFilters
                  ),
                  OnDiskHTTPCapature<HTTPResponseHead>(
                    connection: session,
                    captureFilters: onDiskHTTPCaptureFilters
                  ),
                ]
              )
            },
          ],
          on: inputStream.eventLoop
        )
      },
      name: Recognizer.HTTP.name
    )
  }
}
