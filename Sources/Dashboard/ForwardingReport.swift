//
// See LICENSE.txt for license information
//

import AnlzrReports

extension ForwardingReport {

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public var prettyPrintedRule: String {
    guard let source else {
      return "N/A"
    }

    guard !source.hasPrefix("FINAL") else {
      return "FINAL"
    }

    let components = source.split(separator: /\ *, */).prefix(2)
    guard components.count == 2 else {
      return "N/A"
    }

    guard components[0].hasSuffix("-SET") else {
      return components.joined(separator: " ")
    }
    return "\(components[0]) \(components[1].split(separator: "/").last!)"
  }
}
