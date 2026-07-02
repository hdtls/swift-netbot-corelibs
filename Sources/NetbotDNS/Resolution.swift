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

import NEAddressProcessing

@available(SwiftStdlib 6.0, *)
public struct ResolutionResult<Record: ResourceRecord>: Hashable, Sendable {

  public typealias Source = DNSResolutionSource

  /// The source of this resolution.
  public var source: Source

  /// The length of time in seconds spent on this resolution step.
  public var duration: Duration

  /// The protocl of this DNS resolution.
  public var dnsProtocol: DNSProtocol

  /// The value of resolved resource records discovered by the resolution step.
  public var records: [Record]

  package init(source: Source, duration: Duration, dnsProtocol: DNSProtocol, records: [Record]) {
    self.source = source
    self.duration = duration
    self.dnsProtocol = dnsProtocol
    self.records = records
  }
}
