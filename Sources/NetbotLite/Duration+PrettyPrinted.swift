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

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
extension FormatStyle where Self == Duration.UnitsFormatStyle {

  static func prettyPrinted() -> Self {
    .init(allowedUnits: [.seconds, .milliseconds, .microseconds, .nanoseconds], width: .narrow)
  }
}
