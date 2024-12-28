//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports

struct DomainKeywordForwardingRule: ForwardingRule, ForwardingRuleConvertible, Equatable, Hashable {

  @usableFromInline final class _Storage: Hashable {

    @usableFromInline var domainKeyword: String
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(domainKeyword: String, forwardProtocol: any ForwardProtocolConvertible) {
      self.domainKeyword = domainKeyword
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(domainKeyword: domainKeyword, forwardProtocol: forwardProtocol)
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      lhs.domainKeyword == rhs.domainKeyword
        && lhs.forwardProtocol.asForwardProtocol().name
          == rhs.forwardProtocol.asForwardProtocol().name
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(domainKeyword)
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
    "DOMAIN-KEYWORD,\(domainKeyword),\(forwardProtocol.asForwardProtocol().name)"
  }

  @inlinable var domainKeyword: String {
    get { _storage.domainKeyword }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.domainKeyword = newValue
    }
  }

  @inlinable init(domainKeyword: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domainKeyword: domainKeyword, forwardProtocol: forwardProtocol)
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest.host(percentEncoded: false)?.contains(domainKeyword) ?? false
  }

  @inlinable static func == (lhs: DomainKeywordForwardingRule, rhs: DomainKeywordForwardingRule)
    -> Bool
  {
    lhs.domainKeyword == rhs.domainKeyword && lhs.description == rhs.description
  }
}

extension DomainKeywordForwardingRule: @unchecked Sendable {}
