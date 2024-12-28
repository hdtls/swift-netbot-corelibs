//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports

struct DomainSuffixForwardingRule: ForwardingRule, ForwardingRuleConvertible, Equatable, Hashable {

  @usableFromInline final class _Storage: Hashable {

    @usableFromInline var domainSuffix: String
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(domainSuffix: String, forwardProtocol: any ForwardProtocolConvertible) {
      self.domainSuffix = domainSuffix
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(domainSuffix: domainSuffix, forwardProtocol: forwardProtocol)
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      lhs.domainSuffix == rhs.domainSuffix
        && lhs.forwardProtocol.asForwardProtocol().name
          == rhs.forwardProtocol.asForwardProtocol().name
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(domainSuffix)
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

  @inlinable var description: String {
    "DOMAIN-SUFFIX,\(domainSuffix),\(forwardProtocol.asForwardProtocol().name)"
  }

  @inlinable var domainSuffix: String {
    get { _storage.domainSuffix }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.domainSuffix = newValue
    }
  }

  @inlinable init(domainSuffix: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domainSuffix: domainSuffix, forwardProtocol: forwardProtocol)
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    guard let host = connection.originalRequest.host(percentEncoded: false) else {
      return false
    }
    return host.hasSuffix(domainSuffix)
  }
}

extension DomainSuffixForwardingRule: @unchecked Sendable {}
