//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports

struct DomainForwardingRule: ForwardingRule, ForwardingRuleConvertible, Equatable, Hashable {

  @usableFromInline final class _Storage: Hashable {
    @usableFromInline var domain: String
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(domain: String, forwardProtocol: any ForwardProtocolConvertible) {
      self.domain = domain
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(domain: domain, forwardProtocol: forwardProtocol)
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      lhs.domain == rhs.domain
        && lhs.forwardProtocol.asForwardProtocol().name
          == rhs.forwardProtocol.asForwardProtocol().name
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(domain)
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
    "DOMAIN,\(domain),\(forwardProtocol.asForwardProtocol().name)"
  }

  @inlinable var domain: String {
    get { _storage.domain }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.domain = newValue
    }
  }

  @inlinable init(domain: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domain: domain, forwardProtocol: forwardProtocol)
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest.host(percentEncoded: false) == domain
  }
}

extension DomainForwardingRule: @unchecked Sendable {}
