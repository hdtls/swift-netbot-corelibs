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

import Metrics

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
extension Timer {
  /// Convenience for measuring duration of a closure.
  ///
  /// - Parameters:
  ///   - label: The label for the Timer.
  ///   - dimensions: The dimensions for the `Timer`, as `(name, value)` tuples.
  ///   - clock: The clock used for measuring the duration. Defaults to the continuous clock.
  ///   - isolation: The isolation of the method. Defaults to the isolation of the caller.
  ///   - body: The closure to record the duration of.
  @inlinable
  static func measure<Result, Failure: Error, Clock: _Concurrency.Clock>(
    label: String,
    dimensions: [(String, String)] = [],
    clock: Clock = .continuous,
    isolation: isolated (any Actor)? = #isolation,
    body: () async throws(Failure) -> sending Result
  ) async throws(Failure) -> sending Result where Clock.Duration == Duration {
    let timer = Timer(label: label, dimensions: dimensions)
    return try await timer.measure(clock: clock, isolation: isolation, body: body)
  }
}
