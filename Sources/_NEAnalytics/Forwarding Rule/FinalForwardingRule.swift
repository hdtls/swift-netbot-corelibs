//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization

@_cowOptimization
struct FinalForwardingRule: Anlzr.FinalForwardingRule, ForwardingRuleConvertible, Hashable, Sendable
{

  var condition: String

  var forwardProtocol: any ForwardProtocolConvertible

  @inlinable var description: String {
    "FINAL"
  }

  init(_ condition: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(condition: condition, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    true
  }
}

extension FinalForwardingRule._Storage: Hashable {
  static func == (lhs: FinalForwardingRule._Storage, rhs: FinalForwardingRule._Storage) -> Bool {
    lhs.condition == rhs.condition
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(condition)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

extension FinalForwardingRule._Storage: @unchecked Sendable {}
