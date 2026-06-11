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

@available(SwiftStdlib 6.0, *)
extension AnyProxy {

  /// WebSocket settings for VMESS protocol.
  public struct TLS: Codable, Hashable, Sendable {

    /// A boolean value determine whether TLS should be enabled.
    public var isEnabled: Bool = false

    /// A boolean value determine whether should skip certificate verification.
    public var skipCertificateVerification = false

    /// The custom SNI for TLS connection.
    public var sni: String = ""

    /// The certificate pinning for TLS connection.
    public var certificatePinning: String = ""

    /// Initialize an instance of `TLS` settings with specified parameters.
    public init(
      isEnabled: Bool = false, skipCertificateVerification: Bool = false, sni: String = "",
      certificatePinning: String = ""
    ) {
      self.isEnabled = isEnabled
      self.skipCertificateVerification = skipCertificateVerification
      self.sni = sni
      self.certificatePinning = certificatePinning
    }
  }
}
