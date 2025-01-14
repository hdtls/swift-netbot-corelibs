//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Crypto
private import NEPrettyBytes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

struct RulesetForwardingRule: ForwardingRule, ForwardingRuleConvertible, Equatable, Hashable {

  @usableFromInline final class _Storage: Hashable {
    @usableFromInline var originalURLString: String
    @usableFromInline var externalResourceDirectory: URL
    @usableFromInline var externalRules: [any ForwardingRule]
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible
    @usableFromInline var externalResourceURL: URL {
      let fileURL = externalResourceDirectory
      let digest = Insecure.MD5.hash(data: Array(originalURLString.utf8))
      let filename = Array(digest).hexEncodedString()
      if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
        return fileURL.appending(path: filename)
      } else {
        return fileURL.appendingPathComponent(filename)
      }
    }

    @inlinable init(
      originalURLString: String, externalResourceDirectory: URL,
      externalRules: [any ForwardingRule], forwardProtocol: any ForwardProtocolConvertible
    ) {
      self.originalURLString = originalURLString
      self.externalResourceDirectory = externalResourceDirectory
      self.externalRules = externalRules
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(
        originalURLString: originalURLString, externalResourceDirectory: externalResourceDirectory,
        externalRules: externalRules, forwardProtocol: forwardProtocol)
    }

    @inlinable func processExternalRules() {
      var processResult: [any ForwardingRule] = []
      do {
        let file = try String(contentsOf: externalResourceURL, encoding: .utf8)
        processResult = file.split(separator: "\n").compactMap {
          let parseInput = $0.trimmingCharacters(in: .whitespaces)
          guard !parseInput.hasPrefix("#") else {
            return nil
          }

          let components = parseInput.split(separator: ",")
          guard components.count >= 2 else {
            return nil
          }

          let rawValue = components[0].trimmingCharacters(in: .whitespaces)
          guard let kind = AnyForwardingRule.Kind(rawValue: rawValue) else {
            return nil
          }

          var condition = components[1].components(separatedBy: "//")[0]
          condition = condition.trimmingCharacters(in: .whitespaces)

          switch kind {
          case .domain:
            return DomainForwardingRule(domain: condition, forwardProtocol: forwardProtocol)
          case .domainKeyword:
            return DomainKeywordForwardingRule(
              domainKeyword: condition, forwardProtocol: forwardProtocol)
          case .domainSuffix:
            return DomainSuffixForwardingRule(
              domainSuffix: condition, forwardProtocol: forwardProtocol)
          case .geoip:
            return GeoIPForwardingRule(
              db: nil, countryCode: condition, forwardProtocol: forwardProtocol)
          case .ipcidr:
            return IPCIDRForwardingRule(
              classlessInterDomainRouting: condition, forwardProtocol: forwardProtocol)
          default:
            return nil
          }
        }
      } catch {}

      self.externalRules = processResult
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      lhs.originalURLString == rhs.originalURLString
        && lhs.externalResourceURL == rhs.externalResourceURL
        && lhs.forwardProtocol.asForwardProtocol().name
          == rhs.forwardProtocol.asForwardProtocol().name
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(originalURLString)
      hasher.combine(externalResourceDirectory)
      hasher.combine(forwardProtocol.asForwardProtocol().name)
    }
  }

  @usableFromInline var _storage: _Storage

  @inlinable var forwardProtocol: any ForwardProtocolConvertible {
    get { _storage.forwardProtocol }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.forwardProtocol = newValue
    }
  }

  @inlinable var originalURLString: String {
    get { _storage.originalURLString }
    set {
      guard originalURLString != newValue else { return }
      copyStorageIfNotUniquelyReferenced()
      _storage.originalURLString = newValue
      _storage.processExternalRules()
    }
  }

  @inlinable var externalRules: [any ForwardingRule] {
    get { _storage.externalRules }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.externalRules = newValue
    }
  }

  @inlinable var externalResourceURL: URL {
    _storage.externalResourceURL
  }

  @inlinable var description: String {
    "RULE-SET,\(originalURLString),\(forwardProtocol.asForwardProtocol().name)"
  }

  init(
    externalResourceDirectory: URL = .externalResourceDirectory,
    originalURLString: String, forwardProtocol: any ForwardProtocolConvertible
  ) {
    self._storage = _Storage(
      originalURLString: originalURLString, externalResourceDirectory: externalResourceDirectory,
      externalRules: [], forwardProtocol: forwardProtocol)
    self._storage.processExternalRules()
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    try externalRules.contains { try $0.predicate(connection) }
  }
}

extension RulesetForwardingRule: @unchecked Sendable {}
