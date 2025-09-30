//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2023 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOEmbedded
import Testing

@testable import Anlzr

@Suite struct RecognizerTests {

  @Test func tlsSSLRecognitionThatFirstPacketLengthIsLessThanSix() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    let data = ByteBuffer(bytes: [0x00, 0x01, 0x02, 0x04, 0x0B])
    try channel.writeInbound(data)

    let inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func tlsSSLRecognitionThatRecordTypeIsNotSSL3_RT_HANDSHAKE() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    let data = ByteBuffer(bytes: [0x00, 0x01, 0x02, 0x04, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x14])
    try channel.writeInbound(data)
    let inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }

  @Test func tlsSSLRecognitionThatHandshakeTypeIsNotUnknowned() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    let data = ByteBuffer(bytes: [0x16, 0x01, 0x02, 0x04, 0x0B, 0x11])
    try channel.writeInbound(data)
    let inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }

  @Test func tlsSSLRecognition() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .identified("TLS"))
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    let data = ByteBuffer(bytes: [0x16, 0x01, 0x02, 0x04, 0x0B, 0x14])
    try channel.writeInbound(data)
    let inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }

  @Test func httpRecognitionThatFirstPacketDoseNotContainCRLF() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    let data = ByteBuffer(string: "GET /uri HTTP/1.1")
    try channel.writeInbound(data)
    let inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }

  @Test func httpRecognitionWhereTheFirstLineOfPacketContainsAnIncorrectNumberOfSpaces() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    var data = ByteBuffer(string: "GET/uriHTTP/1.1\r\n")
    try channel.writeInbound(data)
    var inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)

    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    data = ByteBuffer(string: "GET /uriHTTP/1.1\r\n")
    try channel.writeInbound(data)
    inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)

    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    data = ByteBuffer(string: "GET /uri  HTTP/1.1\r\n")
    try channel.writeInbound(data)
    inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }

  @Test func httpRecognitionWhereTheLastComponentOfFirstLineOfPacketDoesNotHasHTTPPrefix() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .tls) { result in
        #expect(result == .fallback)
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    let data = ByteBuffer(string: "GET /uri ABC/1.1\r\n")
    try channel.writeInbound(data)
    let inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }

  @Test func httpRecognition() throws {
    let channel = EmbeddedChannel()
    try channel.pipeline.syncOperations.addHandler(
      CharacteristicIdentificationHandler(recognizer: .http) { result in
        #expect(result == .identified("HTTP"))
        return channel.eventLoop.makeSucceededVoidFuture()
      }
    )

    let data = ByteBuffer(string: "GET /uri HTTP/1.1\r\n")
    try channel.writeInbound(data)
    let inbound = try channel.readInbound(as: ByteBuffer.self)
    #expect(inbound == data)
  }
}
