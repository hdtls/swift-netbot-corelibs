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

/// Forwarding rule base on Process.
@available(SwiftStdlib 5.3, *)
@_cowOptimization
struct ProcessForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var processName: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "PROCESS-NAME \(processName)"
  }

  init(processName: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(processName: processName, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    guard let process = connection.processReport?.program else { return false }
    return process.executableURL?.lastPathComponent == processName
  }
}

@available(SwiftStdlib 5.3, *)
extension ProcessForwardingRule._Storage: Hashable {
  static func == (lhs: ProcessForwardingRule._Storage, rhs: ProcessForwardingRule._Storage) -> Bool
  {
    lhs.processName == rhs.processName
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(processName)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

@available(SwiftStdlib 5.3, *)
extension ProcessForwardingRule._Storage: @unchecked Sendable {}
