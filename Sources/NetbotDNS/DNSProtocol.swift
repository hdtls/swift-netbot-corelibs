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

/// A Resolution.DNSProtocol indicates the protocol used to resolve the endpoint,
/// such as using UDP, TCP, TLS, or HTTPS for DNS.
public enum DNSProtocol: String, Codable, Hashable, Sendable {

  /// The protocol used is not known, or not applicable.
  case unknown

  /// Resolution used DNS over UDP.
  case udp

  /// Resolution used DNS over TCP.
  case tcp

  /// Resolution used DNS over TLS.
  case tls

  /// Resolution used DNS over HTTPS.
  case https
}
