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

@Suite(.tags(.forwardproto))
struct ForwardProtocolHTTPTests {

  @available(SwiftStdlib 6.0, *)
  @Test func initWithAllParameters() {
    // Arrange
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let passwordReference = "passwordRef123"
    let authenticationRequired = false
    let forceHTTPTunneling = true
    let tls = AnyProxy.TLS()

    // Act
    let forwardProtocol = ForwardProtocolHTTP(
      name: name,
      serverAddress: serverAddress,
      port: port,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      forceHTTPTunneling: forceHTTPTunneling,
      tls: tls
    )

    // Assert
    #expect(forwardProtocol.name == name, "Name should be set correctly")
    #expect(
      forwardProtocol.serverAddress == serverAddress, "Server Address should be set correctly")
    #expect(forwardProtocol.port == port, "Port should be set correctly")
    #expect(
      forwardProtocol.passwordReference == passwordReference,
      "Password Reference should be set correctly")
    #expect(
      forwardProtocol.authenticationRequired == authenticationRequired,
      "AuthenticationRequired should be set correctly")
    #expect(
      forwardProtocol.forceHTTPTunneling == forceHTTPTunneling,
      "ForceHTTPTunneling should be set correctly")
    #expect(forwardProtocol.tls == tls, "TLS should be set correctly")
    #expect(forwardProtocol.tlsOptions == tls)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equality() {
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let passwordReference = "passwordRef123"
    let authenticationRequired = false
    let forceHTTPTunneling = true
    let tls = AnyProxy.TLS()

    let forwardProtocol1 = ForwardProtocolHTTP(
      name: name,
      serverAddress: serverAddress,
      port: port,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      forceHTTPTunneling: forceHTTPTunneling,
      tls: tls
    )

    let forwardProtocol2 = ForwardProtocolHTTP(
      name: name,
      serverAddress: serverAddress,
      port: port,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      forceHTTPTunneling: forceHTTPTunneling,
      tls: tls
    )

    let forwardProtocol3 = ForwardProtocolHTTP(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      passwordReference: "anotherRef",
      authenticationRequired: true,
      forceHTTPTunneling: false,
      tls: .init()
    )

    // Assert Equality
    #expect(
      forwardProtocol1 == forwardProtocol2,
      "ForwardProtocolSOCKS5 instances with the same values should be equal")

    // Assert Non-Equality
    #expect(
      forwardProtocol1 != forwardProtocol3,
      "ForwardProtocolSOCKS5 instances with different values should not be equal")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func hashing() {
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let passwordReference = "passwordRef123"
    let authenticationRequired = false
    let forceHTTPTunneling = true
    let tls = AnyProxy.TLS()

    let forwardProtocol1 = ForwardProtocolHTTP(
      name: name,
      serverAddress: serverAddress,
      port: port,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      forceHTTPTunneling: forceHTTPTunneling,
      tls: tls
    )

    let forwardProtocol2 = ForwardProtocolHTTP(
      name: name,
      serverAddress: serverAddress,
      port: port,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      forceHTTPTunneling: forceHTTPTunneling,
      tls: tls
    )

    let forwardProtocol3 = ForwardProtocolHTTP(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      passwordReference: "anotherRef",
      authenticationRequired: true,
      forceHTTPTunneling: true,
      tls: .init()
    )

    var set = Set<ForwardProtocolHTTP>()
    set.insert(forwardProtocol1)
    set.insert(forwardProtocol2)
    set.insert(forwardProtocol3)

    #expect(
      set.count == 2, "Hashable objects with the same values should not be counted twice in a Set")
  }
}
