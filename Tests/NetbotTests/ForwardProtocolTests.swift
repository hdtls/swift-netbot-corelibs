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

import Logging
import NIOCore
import NIOEmbedded
import NetbotLite
import NetbotLiteData
import Testing

@testable import Netbot

@Suite struct ForwardProtocolTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("ForwardProtocolRejectTinyGIF: name is correct and makeConnection throws")
  func rejectTinyGIFHasCorrectNameAndAlwaysThrowsErrorWhenMakeNewConnection() async throws {
    let proto = ForwardProtocolRejectTinyGIF()
    #expect(proto.name == "REJECT-TINYGIF")

    let logger = Logger(label: "test")
    let connection = Connection()
    let eventLoop = EmbeddedEventLoop()

    await #expect(throws: AnalyzeError.self) {
      try await proto.makeConnection(logger: logger, connection: connection, on: eventLoop)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("ForwardProtocolReject: name is correct and makeConnection throws")
  func rejectHasCorrectNameAndAlwaysThrowsErrorWhenMakeNewConnection() async throws {
    let proto = ForwardProtocolReject()
    #expect(proto.name == "REJECT")
    let logger = Logger(label: "test")
    let connection = Connection()
    let eventLoop = EmbeddedEventLoop()

    await #expect(throws: AnalyzeError.self) {
      try await proto.makeConnection(logger: logger, connection: connection, on: eventLoop)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("ForwardProtocolDirect: name is correct")
  func direct() async throws {
    let proto = ForwardProtocolDirect()
    #expect(proto.name == "DIRECT")
  }
}
