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

#if canImport(Darwin)
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension AnyProxy {

  /// Data obfuscation settings.
  public struct Obfuscation: Codable, Hashable, Sendable {

    /// Stream obfuscating strategy.
    public struct Strategy: OptionSet, CaseIterable, Codable, Hashable, Sendable {
      public var rawValue: Int

      public init(rawValue: Int) {
        self.rawValue = rawValue
      }

      /// Obfuscate stream with HTTP protocol.
      public static let http: Strategy = .init(rawValue: 1)

      /// Obfuscate stream with TLS protocol.
      public static let tls: Strategy = .init(rawValue: 1 << 1)

      public static var allCases: [AnyProxy.Obfuscation.Strategy] {
        [.http, .tls]
      }

      @available(SwiftStdlib 5.5, *)
      public var localizedName: String {
        switch self {
        #if canImport(Darwin)
          case .http:
            return String(localized: "HTTP")
          case .tls:
            return String(localized: "TLS")
          default:
            assertionFailure("Unknown obfuscation strategy \(self)")
            return ""
        #else
          case .http:
            return "HTTP"
          case .tls:
            return "TLS"
          default:
            assertionFailure("Unknown obfuscation strategy \(self)")
            return ""
        #endif
        }
      }
    }

    /// A boolean value determine whether this settings should be enabled.
    public var isEnabled = false

    /// The strategy of this obfuscate settings.
    public var strategy: Strategy = .http

    /// The hostname of this obfuscating will use.
    public var hostname: String = ""

    /// Create instance of `Obfuscation` with specified `isEnable` `strategy` and `hostname`.
    public init(isEnabled: Bool = false, strategy: Strategy = .http, hostname: String = "") {
      self.isEnabled = isEnabled
      self.strategy = strategy
      self.hostname = hostname
    }
  }
}
