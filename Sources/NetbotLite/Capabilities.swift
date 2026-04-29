// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

/// An OptionSet for all supported capabilities.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct CapabilityFlags: OptionSet, Hashable, Sendable {

  public typealias RawValue = Int

  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// HTTP body capture.
  public static let httpCapture = CapabilityFlags(rawValue: 1)

  /// HTTPS decryption(MitM).
  public static let httpsDecryption = CapabilityFlags(rawValue: 1 << 1)

  /// Modify HTTP request or response.
  public static let rewrite = CapabilityFlags(rawValue: 1 << 2)
}
