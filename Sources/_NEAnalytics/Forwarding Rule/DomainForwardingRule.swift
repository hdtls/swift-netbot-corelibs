//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization

@_cowOptimization
struct DomainForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domain: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN,\(domain),\(forwardProtocol.asForwardProtocol().name)"
  }

  init(domain: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domain: domain, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest?.host(percentEncoded: false) == domain
  }
}

extension DomainForwardingRule._Storage: Hashable {
  static func == (lhs: DomainForwardingRule._Storage, rhs: DomainForwardingRule._Storage) -> Bool {
    lhs.domain == rhs.domain
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(domain)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

extension DomainForwardingRule._Storage: @unchecked Sendable {}
