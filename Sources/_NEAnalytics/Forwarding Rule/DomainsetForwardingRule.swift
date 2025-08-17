//
// See LICENSE.txt for license information
//

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

struct DomainsetForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  @usableFromInline final class _Storage {

    @usableFromInline var originalURLString: String
    @usableFromInline var externalDomains: [String]
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible
    @usableFromInline let externalResourceDirectory: URL
    @usableFromInline var externalResourceURL: URL {
      let fileURL = externalResourceDirectory
      let digest = Insecure.MD5.hash(data: Array(originalURLString.utf8))
      let filename = ByteBuffer(bytes: digest).hexDump(format: .compact)
      if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
        return fileURL.appending(path: filename)
      } else {
        return fileURL.appendingPathComponent(filename)
      }
    }

    @inlinable init(
      originalURLString: String, externalResourceDirectory: URL, externalDomains: [String],
      forwardProtocol: any ForwardProtocolConvertible
    ) {
      self.originalURLString = originalURLString
      self.externalResourceDirectory = externalResourceDirectory
      self.externalDomains = externalDomains
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(
        originalURLString: originalURLString, externalResourceDirectory: externalResourceDirectory,
        externalDomains: externalDomains, forwardProtocol: forwardProtocol)
    }

    @usableFromInline func processExternalDomains() {
      var processResult: [String] = []
      do {
        let file = try String(contentsOf: externalResourceURL, encoding: .utf8)
        processResult = file.split(separator: "\n").map {
          $0._trimmingWhitespaces()
        }
      } catch {}
      externalDomains = processResult
    }
  }

  @usableFromInline var _storage: _Storage

  @inlinable var forwardProtocol: any ForwardProtocolConvertible {
    get { _storage.forwardProtocol }
    _modify {
      copyStorageIfNotUniquelyReferenced()
      yield &_storage.forwardProtocol
    }
  }

  @inlinable var originalURLString: String {
    get { _storage.originalURLString }
    set {
      guard originalURLString != newValue else { return }
      copyStorageIfNotUniquelyReferenced()
      _storage.originalURLString = newValue
      _storage.processExternalDomains()
    }
  }

  @inlinable var externalDomains: [String] {
    _storage.externalDomains
  }

  @inlinable var externalResourceURL: URL {
    _storage.externalResourceURL
  }

  @inlinable var description: String {
    "DOMAIN-SET,\(originalURLString),\(forwardProtocol.asForwardProtocol().name)"
  }

  /// Create instance of `DomainsetForwardingRule` with specific url and forwardProtocol.
  ///
  /// This initializer will load external resources from cache automatically.
  ///
  @inlinable init(
    externalResourceDirectory: URL = .externalResourceDirectory,
    originalURLString: String, forwardProtocol: any ForwardProtocolConvertible
  ) {
    self._storage = _Storage(
      originalURLString: originalURLString, externalResourceDirectory: externalResourceDirectory,
      externalDomains: [], forwardProtocol: forwardProtocol)
    self._storage.processExternalDomains()
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    guard let host = connection.originalRequest?.host(percentEncoded: false) else {
      return false
    }

    return externalDomains.contains {
      var result = false
      if $0.hasPrefix(".") {
        // Match domain and all sub-domains.
        result = host == String($0.dropFirst()) || ".\(host)".hasSuffix($0)
      } else {
        result = $0 == host
      }
      return result
    }
  }
}

extension DomainsetForwardingRule._Storage: Hashable {
  static func == (lhs: DomainsetForwardingRule._Storage, rhs: DomainsetForwardingRule._Storage)
    -> Bool
  {
    lhs.originalURLString == rhs.originalURLString
      && lhs.externalResourceDirectory == rhs.externalResourceDirectory
      && lhs.externalDomains == rhs.externalDomains
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(originalURLString)
    hasher.combine(externalResourceDirectory)
    hasher.combine(externalDomains)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

extension DomainsetForwardingRule._Storage: @unchecked Sendable {}
