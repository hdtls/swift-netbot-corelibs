//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

extension AnyProxyGroup {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

extension AnyProxyGroup.FormatStyle {
  public func format(_ value: AnyProxyGroup) -> String {
    var formatOutput = "\(value.name) = \(value.kind.rawValue)"
    switch value.resource.source {
    case .cache:
      formatOutput += ", proxies = \(value.lazyProxies.joined(separator: ", "))"
    case .query:
      formatOutput += ", proxies-url = \(value.resource.externalProxiesURL?.absoluteString ?? "")"
      if value.resource.externalProxiesAutoUpdateTimeInterval != 86400 {
        formatOutput +=
          ", proxies-auto-update-time-interval = \(value.resource.externalProxiesAutoUpdateTimeInterval)"
      }
    }
    return formatOutput
  }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AnyProxyGroup.FormatStyle: FormatStyle {
}

extension AnyProxyGroup.FormatStyle {
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public func parse(_ value: String) throws -> AnyProxyGroup {
    func buildError(value: String, example: String) -> CocoaError {
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \"\(example)\"."
      return CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    guard let match = value.firstMatch(of: AnyProxyGroup.regex) else {
      throw buildError(value: value, example: "example = select, proxies = DIRECT, REJECT")
    }
    var parseOutput = AnyProxyGroup(name: match.1._trimmingWhitespaces())
    parseOutput.kind = match.2
    var source: AnyProxyGroup.Resource.Source?

    let properties: [String: [String]]
    do {
      properties = try PropertiesParseStrategy().parse(String(match.3))
    } catch {
      throw buildError(value: value, example: "example = select, proxies = DIRECT, REJECT")
    }

    for property in properties {
      if property.key == "proxies" {
        guard !property.value.isEmpty else {
          // Must contains at least one policy.
          throw buildError(value: value, example: "example = select, proxies = DIRECT, REJECT")
        }
        parseOutput.lazyProxies = property.value
        source = .cache
      }
      //      if let match = property.firstMatch(of: /\ *proxies *= *(.*)/) {
      //        if match.1.isEmpty {
      //          // Must contains at least one policy.
      //          throw buildError(value: value, example: "example = select, proxies = DIRECT, REJECT")
      //        }
      //        parseOutput.lazyProxies = match.1.split(separator: ",").map({ $0._trimmingWhitespaces() })
      //        source = .cache
      //      }
      if property.key == "proxies-url" {
        guard let urlString = property.value.first, let url = URL(string: urlString),
          url.scheme != nil
        else {
          // proxies-url is required for external resource.
          throw buildError(
            value: value, example: "example = select, proxies-url = https://example.com")
        }
        parseOutput.resource.externalProxiesURL = url
        source = .query
      }
      //      if let match = property.firstMatch(of: /\ *proxies-url *= *(.*)/) {
      //        guard let url = URL(string: match.1._trimmingWhitespaces()), url.scheme != nil
      //        else {
      //          // proxies-url is required for external resource.
      //          throw buildError(
      //            value: value, example: "example = select, proxies-url = https://example.com")
      //        }
      //        parseOutput.resource.externalProxiesURL = url
      //        source = .query
      //      }
      if property.key == "proxies-auto-update-time-interval" {
        guard let timeIntervalString = property.value.first,
          let timeInterval = Int(timeIntervalString)
        else {
          throw buildError(
            value: value,
            example:
              "example = select, proxies-url = https://example.com, proxies-auto-update-time-interval = 86400"
          )
        }
        parseOutput.resource.externalProxiesAutoUpdateTimeInterval = timeInterval
      }
      //      if let match = property.firstMatch(of: /\ *proxies-auto-update-time-interval *= *([0-9]*)/) {
      //        guard let timeInterval = Int(match.1._trimmingWhitespaces()) else {
      //          throw buildError(
      //            value: value,
      //            example:
      //              "example = select, proxies-url = https://example.com, proxies-auto-update-time-interval = 86400"
      //          )
      //        }
      //        parseOutput.resource.externalProxiesAutoUpdateTimeInterval = timeInterval
      //      }
    }

    guard let source else {
      throw buildError(value: value, example: "example = select, proxies = DIRECT, REJECT")
    }

    parseOutput.resource.source = source
    return parseOutput
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension AnyProxyGroup.FormatStyle: ParseStrategy {
}

extension AnyProxyGroup.FormatStyle {
  public var parseStrategy: AnyProxyGroup.FormatStyle {
    self
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension AnyProxyGroup.FormatStyle: ParseableFormatStyle {
}

extension AnyProxyGroup.FormatStyle: Codable, Hashable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle where Self == AnyProxyGroup.FormatStyle {
  public static var proxyGroup: Self { .init() }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ParseableFormatStyle where Self == AnyProxyGroup.FormatStyle {
  public static var proxyGroup: Self { .init() }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ParseStrategy where Self == AnyProxyGroup.FormatStyle {
  @_disfavoredOverload
  public static var proxyGroup: Self { .init() }
}

extension AnyProxyGroup {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == AnyProxyGroup {
      return v.format(self)
    }
  #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == AnyProxyGroup {
      v.format(self)
    }
  #endif

  /// Formats `self`.
  /// - Returns: A formatted string to describe the policy.
  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
