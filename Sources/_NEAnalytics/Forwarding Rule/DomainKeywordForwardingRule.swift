//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
@_cowOptimization
struct DomainKeywordForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domainKeyword: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN-KEYWORD \(domainKeyword)"
  }

  init(domainKeyword: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domainKeyword: domainKeyword, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest?.host(percentEncoded: false)?.contains(domainKeyword) ?? false
  }
}

@available(SwiftStdlib 5.3, *)
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

@available(SwiftStdlib 5.3, *)
extension DomainKeywordForwardingRule._Storage: @unchecked Sendable {}
