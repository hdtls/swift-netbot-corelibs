//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports

struct FinalForwardingRule: Anlzr.FinalForwardingRule, ForwardingRuleConvertible, Equatable,
  Hashable
{

  @usableFromInline final class _Storage: Hashable {
    @usableFromInline var condition: String
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(condition: String, forwardProtocol: any ForwardProtocolConvertible) {
      self.condition = condition
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(condition: condition, forwardProtocol: forwardProtocol)
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      lhs.condition == rhs.condition
        && lhs.forwardProtocol.asForwardProtocol().name
          == rhs.forwardProtocol.asForwardProtocol().name
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(condition)
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
    guard condition.isEmpty else {
      return "FINAL,\(condition),\(forwardProtocol.asForwardProtocol().name)"
    }
    return "FINAL,\(forwardProtocol.asForwardProtocol().name)"
  }

  @inlinable var condition: String {
    get { _storage.condition }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.condition = newValue
    }
  }

  @inlinable init(_ condition: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(condition: condition, forwardProtocol: forwardProtocol)
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    true
  }
}

extension FinalForwardingRule: @unchecked Sendable {}
