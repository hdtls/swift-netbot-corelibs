//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin)
  @available(SwiftStdlib 5.3, *)
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

@available(SwiftStdlib 5.3, *)
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

@available(SwiftStdlib 5.5, *)
extension UUID.FormatStyle: FormatStyle {
}

@available(SwiftStdlib 5.5, *)
extension UUID.FormatStyle: ParseStrategy {
}

@available(SwiftStdlib 5.3, *)
extension UUID.FormatStyle {
  public var parseStrategy: UUID.FormatStyle {
    self
  }
}

@available(SwiftStdlib 5.5, *)
extension UUID.FormatStyle: ParseableFormatStyle {
}

@available(SwiftStdlib 5.3, *)
extension UUID.FormatStyle: Codable, Hashable {}

@available(SwiftStdlib 5.5, *)
extension FormatStyle where Self == UUID.FormatStyle {
  public static var uuid: Self { .init() }
}

@available(SwiftStdlib 5.5, *)
extension ParseStrategy where Self == UUID.FormatStyle {
  @_disfavoredOverload
  public static var uuid: Self { .init() }
}

@available(SwiftStdlib 5.3, *)
extension UUID {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == UUID {
      return v.format(self)
    }
  #else
    @available(SwiftStdlib 5.5, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == UUID {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(SwiftStdlib 5.5, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
