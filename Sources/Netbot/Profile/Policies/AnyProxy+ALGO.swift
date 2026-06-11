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

/// Shadowsocks crypto algorithm.
///
/// We don't care about rawValue is uppercase or lowercase for example:
///     Algorithm(rawValue: "aes-128-gcm") == Algorithm(rawValue: "AES-128-GCM") // true
@available(SwiftStdlib 6.0, *)
public enum Algorithm: String, CaseIterable, Codable, Equatable, Hashable, Sendable {

  case aes128Gcm = "AES-128-GCM"
  case aes256Gcm = "AES-256-GCM"
  case chaCha20Poly1305 = "ChaCha20-Poly1305"

  public init?(rawValue: String) {
    switch rawValue.uppercased() {
    case Algorithm.aes128Gcm.rawValue:
      self = .aes128Gcm
    case Algorithm.aes256Gcm.rawValue:
      self = .aes256Gcm
    case Algorithm.chaCha20Poly1305.rawValue.uppercased():
      self = .chaCha20Poly1305
    default:
      return nil
    }
  }
}
