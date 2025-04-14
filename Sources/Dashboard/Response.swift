//
// See LICENSE.txt for license information
//

import AnlzrReports
import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Response {

  public enum FormatStrategy {
    case head
    case body
  }

  public func formatted(strategy: FormatStrategy = .head) -> String {
    guard let httpResponse else {
      return ""
    }

    switch strategy {
    case .head:
      return """
        HTTP/1.1 \(httpResponse.status)
        \(httpResponse.headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
        """
    case .body:
      guard let body else {
        return "No Data".localizedCapitalized
      }
      return String(data: body, encoding: .utf8) ?? "No Data".localizedCapitalized
    }
  }
}
