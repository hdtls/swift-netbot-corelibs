//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import Anlzr
import AnlzrReports
import Crypto
import NIOCore
import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
struct RulesetForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  @usableFromInline final class _Storage {
    @usableFromInline var originalURLString: String
    @usableFromInline var externalResourceDirectory: URL
    @usableFromInline var externalRules: [any ForwardingRule]
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible
    @usableFromInline var externalResourceURL: URL {
      let fileURL = externalResourceDirectory
      let digest = Insecure.MD5.hash(data: Array(originalURLString.utf8))
      let filename = ByteBuffer(bytes: digest).hexDump(format: .compact)

      if #available(SwiftStdlib 5.7, *) {
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
          let parseInput = $0._trimmingWhitespaces()
          guard !parseInput.hasPrefix("#") else {
            return nil
          }

          let components = parseInput.split(separator: ",")
          guard components.count >= 2 else {
            return nil
          }

          let rawValue = components[0]._trimmingWhitespaces()
          guard let kind = AnyForwardingRule.Kind(rawValue: rawValue) else {
            return nil
          }

          var condition = components[1].components(separatedBy: "//")[0]
          condition = condition._trimmingWhitespaces()

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
    "RULE-SET \(originalURLString.split(separator: "/").last.unsafelyUnwrapped)"
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

@available(SwiftStdlib 5.3, *)
extension RulesetForwardingRule._Storage: Hashable {
  static func == (lhs: RulesetForwardingRule._Storage, rhs: RulesetForwardingRule._Storage) -> Bool
  {
    lhs.originalURLString == rhs.originalURLString
      && lhs.externalResourceURL == rhs.externalResourceURL
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(originalURLString)
    hasher.combine(externalResourceDirectory)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

@available(SwiftStdlib 5.3, *)
extension RulesetForwardingRule._Storage: @unchecked Sendable {}
