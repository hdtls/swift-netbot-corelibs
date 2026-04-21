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

import NESS
import Testing

@testable import Netbot

@Suite struct ForwardProtocolSSTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func initWithAllParameters() {
    // Arrange
    let algorithm: NESS.Algorithm = .aes128Gcm
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let passwordReference = "passwordRef123"

    // Act
    let forwardProtocol = ForwardProtocolSS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      algorithm: algorithm,
      passwordReference: passwordReference
    )

    // Assert
    #expect(forwardProtocol.name == name, "Name should be set correctly")
    #expect(
      forwardProtocol.serverAddress == serverAddress, "Server Address should be set correctly")
    #expect(forwardProtocol.port == port, "Port should be set correctly")
    #expect(forwardProtocol.algorithm == algorithm, "Algorithm should be set correctly")
    #expect(
      forwardProtocol.passwordReference == passwordReference,
      "Password Reference should be set correctly")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equality() {
    let algorithm: NESS.Algorithm = .aes128Gcm
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let passwordReference = "passwordRef123"

    let forwardProtocol1 = ForwardProtocolSS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      algorithm: algorithm,
      passwordReference: passwordReference
    )

    let forwardProtocol2 = ForwardProtocolSS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      algorithm: algorithm,
      passwordReference: passwordReference
    )

    let forwardProtocol3 = ForwardProtocolSS(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      algorithm: algorithm,
      passwordReference: "anotherRef"
    )

    // Assert Equality
    #expect(
      forwardProtocol1 == forwardProtocol2,
      "ForwardProtocolSS instances with the same values should be equal")

    // Assert Non-Equality
    #expect(
      forwardProtocol1 != forwardProtocol3,
      "ForwardProtocolSS instances with different values should not be equal")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashing() {
    let algorithm: NESS.Algorithm = .aes128Gcm
    let name = "ForwardProtocol1"
    let serverAddress = "192.168.0.1"
    let port = 8080
    let passwordReference = "passwordRef123"

    let forwardProtocol1 = ForwardProtocolSS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      algorithm: algorithm,
      passwordReference: passwordReference
    )

    let forwardProtocol2 = ForwardProtocolSS(
      name: name,
      serverAddress: serverAddress,
      port: port,
      algorithm: algorithm,
      passwordReference: passwordReference
    )

    let forwardProtocol3 = ForwardProtocolSS(
      name: "AnotherProtocol",
      serverAddress: "192.168.0.2",
      port: 9090,
      algorithm: algorithm,
      passwordReference: "anotherRef"
    )

    var set = Set<ForwardProtocolSS>()
    set.insert(forwardProtocol1)
    set.insert(forwardProtocol2)
    set.insert(forwardProtocol3)

    #expect(
      set.count == 2, "Hashable objects with the same values should not be counted twice in a Set")
  }
}
