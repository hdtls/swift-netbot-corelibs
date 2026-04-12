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
import NEAddressProcessing
import NIOCore
import NIOEmbedded
import NIOSSL
import NetbotLiteData
import Testing

@testable import NetbotLite

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

struct MitMPipelineSetupTests {

  var decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle {
    get throws {
      let base64EncodedNoPassP12 = """
        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
        """
      return try NIOSSLPKCS12Bundle(
        buffer: Array(
          Data(base64Encoded: base64EncodedNoPassP12, options: .ignoreUnknownCharacters)!))
    }
  }

  @Test func setUpMitMClientPipelineForConnectionThatHostOfOriginalRequestIsNil() throws {
    let channel = EmbeddedChannel()
    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLClientHandler.self).map { _ in }.wait()
    }

    try channel
      .configureTLSMitMPipeline(
        logger: .init(label: "test"),
        connection: .init(),
        decryptionDNSNames: []
      ).wait()

    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLClientHandler.self).map { _ in }.wait()
    }
  }

  @Test func setUpMitMServerPipelineForConnectionThatHostOfOriginalRequestIsNil() throws {
    let channel = EmbeddedChannel()
    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLServerHandler.self).map { _ in }.wait()
    }

    try channel
      .configureTLSMitMPipeline(
        logger: .init(label: "test"),
        connection: .init(),
        decryptionDNSNames: [],
        decryptionSSLPKCS12Bundle: decryptionSSLPKCS12Bundle
      ).wait()

    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLServerHandler.self).map { _ in }.wait()
    }
  }

  @Test func setUpMitMClientPipelineForConnectionThatHostDoesNotContainedInDecryptionHosts() throws
  {
    let channel = EmbeddedChannel()
    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLClientHandler.self).map { _ in }.wait()
    }

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
    try channel
      .configureTLSMitMPipeline(
        logger: .init(label: "test"),
        connection: connection,
        decryptionDNSNames: ["another-example.com"]
      ).wait()

    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLClientHandler.self).map { _ in }.wait()
    }
  }

  @Test func setUpMitMServerPipelineForConnectionThatHostDoesNotContainedInDecryptionHosts()
    throws
  {
    let channel = EmbeddedChannel()
    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLServerHandler.self).map { _ in }.wait()
    }

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
    try channel
      .configureTLSMitMPipeline(
        logger: .init(label: "test"),
        connection: connection,
        decryptionDNSNames: ["another-example.com"],
        decryptionSSLPKCS12Bundle: decryptionSSLPKCS12Bundle
      ).wait()

    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLServerHandler.self).map { _ in }.wait()
    }
  }

  @Test(arguments: ["www.example.com", "*.example.com"])
  func setUpMitMClientPipeline(dnsName: String) throws {
    let channel = EmbeddedChannel()
    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLClientHandler.self).map { _ in }.wait()
    }

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "www.example.com", port: 443))
    try channel
      .configureTLSMitMPipeline(
        logger: .init(label: "test"),
        connection: connection,
        decryptionDNSNames: [dnsName]
      ).wait()

    #expect(throws: Never.self) {
      try channel.pipeline.handler(type: NIOSSLClientHandler.self).map { _ in }.wait()
    }
  }

  @Test(arguments: ["www.example.com", "*.example.com"])
  func setUpMitMServerPipeline(dnsName: String) throws {
    let channel = EmbeddedChannel()
    #expect(throws: ChannelPipelineError.self) {
      try channel.pipeline.handler(type: NIOSSLServerHandler.self).map { _ in }.wait()
    }

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "www.example.com", port: 443))
    try channel
      .configureTLSMitMPipeline(
        logger: .init(label: "test"),
        connection: connection,
        decryptionDNSNames: [dnsName],
        decryptionSSLPKCS12Bundle: decryptionSSLPKCS12Bundle
      ).wait()

    #expect(throws: Never.self) {
      try channel.pipeline.handler(type: NIOSSLServerHandler.self).map { _ in }.wait()
    }
  }
}
