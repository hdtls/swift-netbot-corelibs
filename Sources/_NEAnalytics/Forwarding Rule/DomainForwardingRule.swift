//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization

@available(SwiftStdlib 5.3, *)
@_cowOptimization
struct DomainForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domain: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN \(domain)"
  }

  init(domain: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domain: domain, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest?.host(percentEncoded: false) == domain
  }
}

@available(SwiftStdlib 5.3, *)
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

@available(SwiftStdlib 5.3, *)
extension DomainForwardingRule._Storage: @unchecked Sendable {}
