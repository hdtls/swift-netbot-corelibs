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
import NetbotLiteData
import Testing

@testable import NetbotLite

struct CapabilityFlagsBuildTests {

  @available(SwiftStdlib 6.0, *)
  @Test func buildTLS() async throws {
    let inputStream = EmbeddedChannel()
    let outputStream = EmbeddedChannel()
    CapabilityFlags.httpsDecryption
      .buildTLS(
        connection: .init(),
        decryptionDNSNames: [],
        decryptionSSLPKCS12Bundle: nil,
        inputStream: inputStream,
        outputStream: outputStream
      )

    await #expect(throws: Never.self) {
      try await inputStream.pipeline.containsHandler(name: Recognizer.TLS.name).get()
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func buildHTTPCapture() async throws {
    let inputStream = EmbeddedChannel()
    let outputStream = EmbeddedChannel()
    CapabilityFlags.httpsDecryption
      .buildHTTP(
        connection: .init(),
        inMemoryHTTPCaptureFilters: [],
        onDiskHTTPCaptureFilters: [],
        inputStream: inputStream,
        outputStream: outputStream
      )

    await #expect(throws: Never.self) {
      try await inputStream.pipeline.containsHandler(name: Recognizer.HTTP.name).get()
    }
  }
}
