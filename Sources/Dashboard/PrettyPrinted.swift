//
// See LICENSE.txt for license information
//

#if swift(>=6.3) || canImport(Darwin)
  import AnlzrReports
  import HTTPTypes

  #if canImport(FoundationEssentials)
    import FoundationInternationalization
  #else
    import Foundation
  #endif

  @available(SwiftStdlib 5.9, *)
  extension Connection.PersistentModel {

    /// Pretty printed forwarding policy.
    public var forwardingPolicy: String {
      "\(forwardingReport?.forwardProtocol ?? "FINAL") (\(forwardingReport?.forwardingRule ?? "*"))"
    }

    public var maximumUploadBandwidthString: String { "" }

    public var maximumDowloadBandwidthString: String { "" }

    /// The name of the application layer protocol if available or transport layer protocol.
    public var protocolName: String {
      guard let httpRequest = currentRequest?.httpRequest else {
        return "TCP"
      }
      return (httpRequest.scheme ?? "TCP").uppercased()
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension Data {
    public var textLiteral: String {
      String(data: self, encoding: .utf8) ?? "No Data".localizedCapitalized
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension HTTPRequest {
    public var textLiteral: String {
      """
      \(method) \(host(percentEncoded: false) ?? ""):\(port ?? 443) HTTP/1.1
      Host: \(host(percentEncoded: false) ?? "")
      \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
      """
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension HTTPResponse {
    public var textLiteral: String {
      """
      HTTP/1.1 \(status)
      \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
      """
    }
  }
#endif
