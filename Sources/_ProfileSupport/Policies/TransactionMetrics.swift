//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// An object that encapsualtes the performance metrics during the execution of a network speed test.
public struct TransactionMetrics: Codable, Equatable, Hashable, Sendable {

  /// The maximum amount of data that can be transmitted over a network in a given amount of time.
  public var bandwidth: Int

  /// The lag or dely in data transmission over a netwrok.
  public var latency: Int

  /// RTT, the time it takes for a packet to travel from sender to the receive and back again.
  public var roundTripTime: Int

  /// PLR, the number of packets that fail to transfer from one destination to another.
  public var packetLoss: Int

  public var creationDate: Date

  public init() {
    self.bandwidth = 0
    self.latency = .max
    self.roundTripTime = .max
    self.packetLoss = 100
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      creationDate = .now
    } else {
      creationDate = .init()
    }
  }
}
