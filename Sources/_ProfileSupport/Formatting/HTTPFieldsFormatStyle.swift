//
// See LICENSE.txt for license information
//

import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

extension HTTPFields {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

extension HTTPFields.FormatStyle {
  public func format(_ value: HTTPFields) -> String {
    var formattedString = ""
    for field in value {
      formattedString += "|\(field.name):\(field.value)"
    }
    // Drop first `|`.
    return formattedString.isEmpty ? "" : String(formattedString.dropFirst())
  }
}

@available(SwiftStdlib 5.5, *)
extension HTTPFields.FormatStyle: FormatStyle {
}

@available(SwiftStdlib 5.7, *)
extension HTTPFields.FormatStyle {
  public func parse(_ value: String) throws -> HTTPFields {
    let fields: [HTTPField] = value.split(separator: "|").compactMap {
      let matches = $0.matches(of: /\ *(.+): *(.+)/)
      guard let match = matches.first else {
        return nil
      }
      guard let name = HTTPField.Name(String(match.1)) else {
        return nil
      }
      return HTTPField(name: name, value: String(match.2))
    }

    guard !fields.isEmpty else {
      let exampleFormattedString = HTTPFields.FormatStyle().format(
        HTTPFields([.init(name: .connection, value: "keep-alive")]))
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }
    let httpFields = HTTPFields(fields)
    return httpFields
  }
}

@available(SwiftStdlib 5.7, *)
extension HTTPFields.FormatStyle: ParseStrategy {
}

extension HTTPFields.FormatStyle {
  public var parseStrategy: HTTPFields.FormatStyle {
    self
  }
}

@available(SwiftStdlib 5.7, *)
extension HTTPFields.FormatStyle: ParseableFormatStyle {
}

extension HTTPFields.FormatStyle: Codable, Hashable {}

@available(SwiftStdlib 5.5, *)
extension FormatStyle where Self == HTTPFields.FormatStyle {
  public static var httpFields: Self { .init() }
}

@available(SwiftStdlib 5.7, *)
extension ParseStrategy where Self == HTTPFields.FormatStyle {
  @_disfavoredOverload
  public static var httpFields: Self { .init() }
}

extension HTTPFields {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == HTTPFields {
      return v.format(self)
    }
  #else
    @available(SwiftStdlib 5.5, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == HTTPFields {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(SwiftStdlib 5.7, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
