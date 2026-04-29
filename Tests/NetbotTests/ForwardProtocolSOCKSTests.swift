// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Testing

@testable import Netbot

@Suite struct ForwardProtocolSOCKSTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func initWithAllParameters() {
    // Arrange
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let username = "username123"
    let passwordReference = "passwordRef123"
    let authenticationRequired = false
    let tls = AnyProxy.TLS()

    // Act
    let forwardProtocol = ForwardProtocolSOCKS5(
      name: name,
      serverAddress: serverAddress,
      port: port,
      username: username,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      tls: tls
    )

    // Assert
    #expect(forwardProtocol.name == name, "Name should be set correctly")
    #expect(
      forwardProtocol.serverAddress == serverAddress, "Server Address should be set correctly")
    #expect(forwardProtocol.port == port, "Port should be set correctly")
    #expect(forwardProtocol.username == username, "Username should be set correctly")
    #expect(
      forwardProtocol.passwordReference == passwordReference,
      "Password Reference should be set correctly")
    #expect(
      forwardProtocol.authenticationRequired == authenticationRequired,
      "AuthenticationRequired should be set correctly")
    #expect(forwardProtocol.tls == tls, "TLS should be set correctly")
    #expect(forwardProtocol.tlsOptions == tls)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equality() {
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let username = "username123"
    let passwordReference = "passwordRef123"
    let authenticationRequired = false
    let tls = AnyProxy.TLS()

    // Act
    let forwardProtocol1 = ForwardProtocolSOCKS5(
      name: name,
      serverAddress: serverAddress,
      port: port,
      username: username,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      tls: tls
    )

    let forwardProtocol2 = ForwardProtocolSOCKS5(
      name: name,
      serverAddress: serverAddress,
      port: port,
      username: username,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      tls: tls
    )

    let forwardProtocol3 = ForwardProtocolSOCKS5(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      username: "sdf",
      passwordReference: "anotherRef",
      authenticationRequired: true,
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashing() {
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let username = "username123"
    let passwordReference = "passwordRef123"
    let authenticationRequired = false
    let tls = AnyProxy.TLS()

    // Act
    let forwardProtocol1 = ForwardProtocolSOCKS5(
      name: name,
      serverAddress: serverAddress,
      port: port,
      username: username,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      tls: tls
    )

    let forwardProtocol2 = ForwardProtocolSOCKS5(
      name: name,
      serverAddress: serverAddress,
      port: port,
      username: username,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      tls: tls
    )
    let forwardProtocol3 = ForwardProtocolSOCKS5(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      username: "sdf",
      passwordReference: "anotherRef",
      authenticationRequired: true,
      tls: .init()
    )

    var set = Set<ForwardProtocolSOCKS5>()
    set.insert(forwardProtocol1)
    set.insert(forwardProtocol2)
    set.insert(forwardProtocol3)

    #expect(
      set.count == 2, "Hashable objects with the same values should not be counted twice in a Set")
  }
}
