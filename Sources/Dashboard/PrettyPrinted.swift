//
// See LICENSE.txt for license information
//

import AnlzrReports
import HTTPTypes

extension Connection {

  /// Formatted earliest begin date.
  public var formattedEarliestBeginDate: String {
    earliestBeginDate.formatted(.dateTime.hour().minute().second())
  }

  /// Formatted data transfer duration.
  public var duration: String {
    self.dataTransferReport?.duration
      .formatted(
        .units(
          allowed: [.hours, .minutes, .seconds, .milliseconds],
          width: .narrow,
          maximumUnitCount: 2
        )
      ) ?? "0ms"
  }

  /// Pretty printed forwarding policy.
  public var forwardingPolicy: String {
    "\(forwardingReport?.forwardProtocol ?? "FINAL") (\(forwardingReport?.forwardingRule ?? "*"))"
  }

  /// Formatted total received application byte count of the connection.
  public var receivedApplicationByteCount: String {
    Int64(clamping: dataTransferReport?.aggregatePathReport.sentApplicationByteCount ?? 0)
      .formatted(.byteCount(style: .binary, spellsOutZero: false))
  }

  /// Formatted total sent application byte count of the connection.
  public var sentApplicationByteCount: String {
    Int64(clamping: dataTransferReport?.aggregatePathReport.receivedApplicationByteCount ?? 0)
      .formatted(.byteCount(style: .binary, spellsOutZero: false))
  }

  /// The name of the application layer protocol if available or transport layer protocol.
  public var protocolName: String {
    guard let httpRequest = currentRequest?.httpRequest else {
      return "TCP"
    }
    return (httpRequest.scheme ?? "TCP").uppercased()
  }

  /// The `URL` string of the current request of the `Connection`.
  public var currentRequestURLString: String {
    currentRequest?.url() ?? ""
  }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Connection.PersistentModel {

  /// Formatted earliest begin date.
  public var formattedEarliestBeginDate: String {
    earliestBeginDate.formatted(.dateTime.hour().minute().second())
  }

  /// Formatted data transfer duration.
  public var duration: String {
    self.dataTransferReport?.duration
      .formatted(
        .units(
          allowed: [.hours, .minutes, .seconds, .milliseconds],
          width: .narrow,
          maximumUnitCount: 2
        )
      ) ?? "0ms"
  }

  /// Pretty printed forwarding policy.
  public var forwardingPolicy: String {
    "\(forwardingReport?.forwardProtocol ?? "FINAL") (\(forwardingReport?.forwardingRule ?? "*"))"
  }

  /// Formatted total received application byte count of the connection.
  public var receivedApplicationByteCount: String {
    Int64(clamping: dataTransferReport?.aggregatePathReport.sentApplicationByteCount ?? 0)
      .formatted(.byteCount(style: .binary, spellsOutZero: false))
  }

  /// Formatted total sent application byte count of the connection.
  public var sentApplicationByteCount: String {
    Int64(clamping: dataTransferReport?.aggregatePathReport.receivedApplicationByteCount ?? 0)
      .formatted(.byteCount(style: .binary, spellsOutZero: false))
  }

  public var realtimeUploadSpeedString: String {
    Int64(clamping: dataTransferReport?.pathReports.first?.sentApplicationByteCount ?? 0)
      .formatted(.byteCount(style: .binary))
      .appending("/s")
  }

  public var realtimeDownloadSpeedString: String {
    Int64(clamping: dataTransferReport?.pathReports.first?.receivedApplicationByteCount ?? 0)
      .formatted(.byteCount(style: .binary))
      .appending("/s")
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

  /// The `URL` string of the current request of the `Connection`.
  public var currentRequestURLString: String {
    currentRequest?.url() ?? ""
  }
}

extension Data {
  public var textLiteral: String {
    String(data: self, encoding: .utf8) ?? "No Data".localizedCapitalized
  }
}

extension HTTPRequest {
  public var textLiteral: String {
    """
    \(method) \(host(percentEncoded: false) ?? ""):\(port ?? 443) HTTP/1.1
    Host: \(host(percentEncoded: false) ?? "")
    \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
    """
  }
}

extension HTTPResponse {
  public var textLiteral: String {
    """
    HTTP/1.1 \(status)
    \(headerFields.map  { "\($0.name): \($0.value)" }.joined(separator: "\n"))
    """
  }
}
