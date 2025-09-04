//
// See LICENSE.txt for license information
//

import Logging
import _DNSSupport

@available(SwiftStdlib 5.3, *)
extension Message {

  enum FormatStyle {
    case standard
    case detailed
  }

  func formatted(_ style: FormatStyle = .standard) -> String {
    var msg = "Standard query"
    if headerFields.flags.isResponse {
      msg += " response"
    }
    msg += " \(headerFields.transactionID)"
    msg += questions.map { " \($0.queryType) \($0.domainName)" }.joined()

    guard style == .detailed else {
      return msg
    }

    msg += answerRRs.map { " \($0.dataType) \($0.domainName)" }.joined()
    msg += authorityRRs.map { " \($0.dataType) \($0.domainName)" }.joined()
    msg += additionalRRs.map { " \($0.dataType) \($0.domainName)" }.joined()
    return msg
  }
}
