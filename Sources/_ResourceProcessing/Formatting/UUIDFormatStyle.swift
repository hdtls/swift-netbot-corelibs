//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

#if canImport(Darwin)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension UUID.FormatStyle: FormatStyle {
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension UUID.FormatStyle: ParseStrategy {
}

extension UUID.FormatStyle {
  public var parseStrategy: UUID.FormatStyle {
    self
  }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension UUID.FormatStyle: ParseableFormatStyle {
}

extension UUID.FormatStyle: Codable, Hashable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle where Self == UUID.FormatStyle {
  public static var uuid: Self { .init() }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension ParseStrategy where Self == UUID.FormatStyle {
  @_disfavoredOverload
  public static var uuid: Self { .init() }
}

extension UUID {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == UUID {
      return v.format(self)
    }
  #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == UUID {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
