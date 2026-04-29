// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

// swift-format-ignore: AvoidRetroactiveConformances
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Date: @retroactive RawRepresentable {

  public var rawValue: String {
    self.timeIntervalSinceReferenceDate.description
  }

  public init?(rawValue: RawValue) {
    guard let timeInterval = TimeInterval(rawValue) else {
      return nil
    }
    self = Date(timeIntervalSinceReferenceDate: timeInterval)
  }
}
