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

#if canImport(Darwin)
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
public struct CapabilityFlags: OptionSet, Hashable, RawRepresentable, Sendable {

  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let httpCapture = CapabilityFlags(rawValue: 1)
  public static let httpsDecryption = CapabilityFlags(rawValue: 1 << 1)
  public static let rewrite = CapabilityFlags(rawValue: 1 << 2)
  public static let scripting = CapabilityFlags(rawValue: 1 << 3)
}

@available(SwiftStdlib 6.0, *)
extension CapabilityFlags {

  public var localizedName: String {
    #if canImport(Darwin)
      switch self {
      case .httpCapture:
        return String(
          localized: "Enable HTTP Capture", comment: "CapabilityFlags for HTTP Capture")
      case .httpsDecryption:
        return String(localized: "Enable HTTPS MitM", comment: "CapabilityFlags for HTTPS MitM")
      case .rewrite:
        return String(localized: "Enable Rewrite", comment: "CapabilityFlags for Rewrite")
      case .scripting:
        return String(
          localized: "Enable Scripting",
          comment: "CapabilityFlags for Scripting"
        )
      default: return "UNKNOWN(\(self.rawValue))"
      }
    #else
      switch self {
      case .httpCapture: return "Enable HTTP Capture"
      case .httpsDecryption: return "Enable HTTPS MitM"
      case .rewrite: return "Enable Rewrite"
      case .scripting: return "Enable Scripting"
      default: return "UNKNOWN(\(self.rawValue))"
      }
    #endif
  }
}

@available(SwiftStdlib 6.0, *)
extension CapabilityFlags {

  public static var allCases: [CapabilityFlags] {
    [.httpCapture, .httpsDecryption, .rewrite, .scripting]
  }
}
