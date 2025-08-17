//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization

@_cowOptimization
struct DomainSuffixForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domainSuffix: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN-SUFFIX,\(domainSuffix),\(forwardProtocol.asForwardProtocol().name)"
  }

  init(domainSuffix: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domainSuffix: domainSuffix, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    guard let host = connection.originalRequest?.host(percentEncoded: false) else {
      return false
    }
    return host.hasSuffix(domainSuffix)
  }
}

extension DomainSuffixForwardingRule._Storage: Hashable {
  static func == (
    lhs: DomainSuffixForwardingRule._Storage, rhs: DomainSuffixForwardingRule._Storage
  ) -> Bool {
    lhs.domainSuffix == rhs.domainSuffix
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(domainSuffix)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

extension DomainSuffixForwardingRule._Storage: @unchecked Sendable {}
