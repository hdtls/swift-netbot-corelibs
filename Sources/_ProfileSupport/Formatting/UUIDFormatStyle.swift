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

#if canImport(Darwin)
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension UUID {
    public class Formatter: Foundation.Formatter {
      public override func string(for obj: Any?) -> String? {
        if let obj = obj as? UUID {
          return string(for: obj)
        }

        if let uuidString = obj as? String, let obj = UUID(uuidString: uuidString) {
          return string(for: obj)
        }

        return nil
      }

      public func string(for uuid: UUID) -> String {
        return uuid.uuidString
      }

      public override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
      ) -> Bool {
        guard let uuid = UUID(uuidString: string) else {
          let exampleFormattedString = UUID.FormatStyle().format(UUID())
          let errorStr =
            "Cannot parse \(string). String should adhere to the preferred format of the locale, such as \(exampleFormattedString)."
          error?.pointee = errorStr as NSString
          return false
        }
        obj?.pointee = uuid as AnyObject
        return true
      }
    }
  }
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension UUID {
  public struct FormatStyle: Sendable {
    public init() {}

    public func format(_ value: UUID) -> String {
      value.uuidString
    }

    public func parse(_ value: String) throws -> UUID {
      guard let uuid = UUID(uuidString: value) else {
        let exampleFormattedString = UUID().uuidString
        let errorStr =
          "Cannot parse \(value). String should adhere to the preferred format of the locale, such as \(exampleFormattedString)."
        throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
      }
      return uuid
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension UUID.FormatStyle: FormatStyle {
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension UUID.FormatStyle: ParseStrategy {
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension UUID.FormatStyle {
  public var parseStrategy: UUID.FormatStyle {
    self
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension UUID.FormatStyle: ParseableFormatStyle {
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension UUID.FormatStyle: Codable, Hashable {}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension FormatStyle where Self == UUID.FormatStyle {
  public static var uuid: Self { .init() }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ParseStrategy where Self == UUID.FormatStyle {
  @_disfavoredOverload
  public static var uuid: Self { .init() }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension UUID {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == UUID {
      return v.format(self)
    }
  #else
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      @available(SwiftStdlib 5.5, *)
    #endif
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == UUID {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.5, *)
  #endif
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
