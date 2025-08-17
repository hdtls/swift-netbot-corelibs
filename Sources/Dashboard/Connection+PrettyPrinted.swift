//
// See LICENSE.txt for license information
//

import AnlzrReports
import HTTPTypes

@_spi(SwiftUI) extension Connection {

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
@_spi(SwiftUI) extension Connection.PersistentModel {

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
