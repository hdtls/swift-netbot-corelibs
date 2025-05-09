//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization

@_cowOptimization
struct DomainKeywordForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domainKeyword: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN-KEYWORD,\(domainKeyword),\(forwardProtocol.asForwardProtocol().name)"
  }

  init(domainKeyword: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domainKeyword: domainKeyword, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest.host(percentEncoded: false)?.contains(domainKeyword) ?? false
  }

  static func == (lhs: DomainKeywordForwardingRule, rhs: DomainKeywordForwardingRule)
    -> Bool
  {
    lhs.domainKeyword == rhs.domainKeyword && lhs.description == rhs.description
  }
}

extension DomainKeywordForwardingRule._Storage: Hashable {
  static func == (
    lhs: DomainKeywordForwardingRule._Storage, rhs: DomainKeywordForwardingRule._Storage
  ) -> Bool {
    lhs.domainKeyword == rhs.domainKeyword
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(domainKeyword)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

extension DomainKeywordForwardingRule._Storage: @unchecked Sendable {}
