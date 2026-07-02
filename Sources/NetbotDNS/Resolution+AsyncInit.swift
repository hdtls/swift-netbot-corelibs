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

// There is a bug for swift-foramt, until that bug fixed, we ignore the file.
// swift-format-ignore-file

@available(SwiftStdlib 6.0, *)
extension ResolutionResult {
  nonisolated(nonsending) package init(
    source: Source, dnsProtocol: DNSProtocol,
    catching body: nonisolated(nonsending) () async throws -> [Record]
  ) async rethrows {
    let startTime = ContinuousClock.now
    self.records = try await body()
    self.source = source
    self.duration = startTime.duration(to: .now)
    self.dnsProtocol = dnsProtocol
  }
}
