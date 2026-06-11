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

import NetbotProfile
import Testing

@testable import Netbot

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.forwardproto))
struct ForwardProtocolVMESSTests {

  @available(SwiftStdlib 6.0, *)
  @Test func initWithAllParameters() {
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let userID = UUID()
    let ws = AnyProxy.WebSocket(uri: "/ws")
    let tls = AnyProxy.TLS()

    let forwardProtocol = ForwardProtocolVMESS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      userID: userID,
      ws: ws,
      tls: tls
    )

    #expect(forwardProtocol.name == name, "Name should be set correctly")
    #expect(
      forwardProtocol.serverAddress == serverAddress, "Server Address should be set correctly")
    #expect(forwardProtocol.port == port, "Port should be set correctly")
    #expect(forwardProtocol.userID == userID, "UserID should be set correctly")
    #expect(forwardProtocol.ws == ws, "WebSocket should be set correctly")
    #expect(forwardProtocol.tls == tls, "TLS should be set correctly")
    #expect(forwardProtocol.tlsOptions == tls)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equality() {
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let userID = UUID()
    let ws = AnyProxy.WebSocket(uri: "/ws")
    let tls = AnyProxy.TLS()

    let forwardProtocol1 = ForwardProtocolVMESS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      userID: userID,
      ws: ws,
      tls: tls
    )

    let forwardProtocol2 = ForwardProtocolVMESS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      userID: userID,
      ws: ws,
      tls: tls
    )
    let forwardProtocol3 = ForwardProtocolVMESS(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      userID: UUID(),
      ws: .init(),
      tls: .init()
    )
    #expect(
      forwardProtocol1 == forwardProtocol2,
      "ForwardProtocolVMESS instances with the same values should be equal")
    #expect(
      forwardProtocol1 != forwardProtocol3,
      "ForwardProtocolVMESS instances with different values should not be equal")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func hashing() {
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let userID = UUID()
    let ws = AnyProxy.WebSocket(uri: "/ws")
    let tls = AnyProxy.TLS()

    let forwardProtocol1 = ForwardProtocolVMESS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      userID: userID,
      ws: ws,
      tls: tls
    )

    let forwardProtocol2 = ForwardProtocolVMESS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      userID: userID,
      ws: ws,
      tls: tls
    )
    let forwardProtocol3 = ForwardProtocolVMESS(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      userID: UUID(),
      ws: .init(),
      tls: .init()
    )

    var set = Set<ForwardProtocolVMESS>()
    set.insert(forwardProtocol1)
    set.insert(forwardProtocol2)
    set.insert(forwardProtocol3)

    #expect(
      set.count == 2, "Hashable objects with the same values should not be counted twice in a Set")
  }
}
