//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2022 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AnlzrReports
import Dispatch
import NIOCore

#if canImport(Network)
  import Network
  import NIOTransportServices
#endif

/// A pending data transfer report collector represents a report that was started
/// with startDataTransferReport(), and may be collected to generate
/// a completed DataTransferReport.
@available(SwiftStdlib 5.3, *)
protocol DataTransferReportCollector: Sendable {

  @preconcurrency func collect(
    queue: DispatchQueue, completion: @escaping @Sendable (_ report: DataTransferReport) -> Void)
}

@available(SwiftStdlib 5.3, *)
extension Channel {

  /// Request pending data transfer report.
  func pendingDataTransferReport() -> EventLoopFuture<any DataTransferReportCollector> {
    #if canImport(Network)
      getOption(NIOTSChannelOptions.dataTransferReport).map {
        $0 as any DataTransferReportCollector
      }
    #else
      eventLoop.makeSucceededFuture(PendingDataTransferReport())
    #endif
  }

  /// Request collection of values in a DataTransferReport.
  func dataTransferReport(_ pendingDataTransferReport: any DataTransferReportCollector)
    -> EventLoopFuture<DataTransferReport>
  {
    let promise = eventLoop.makePromise(of: DataTransferReport.self)
    pendingDataTransferReport.collect(queue: .global()) { dataTransferReport in
      promise.succeed(dataTransferReport)
    }
    return promise.futureResult
  }
}

#if canImport(Network)
  @available(SwiftStdlib 5.3, *)
  extension NWConnection.PendingDataTransferReport: DataTransferReportCollector {

    func collect(
      queue: DispatchQueue, completion: @escaping @Sendable (DataTransferReport) -> Void
    ) {
      self.collect(queue: queue) { dataTransferReport in
        completion(
          DataTransferReport(
            duration: dataTransferReport.duration,
            aggregatePathReport: .init(
              receivedIPPacketCount: dataTransferReport.aggregatePathReport.receivedIPPacketCount,
              sentIPPacketCount: dataTransferReport.aggregatePathReport.sentIPPacketCount,
              receivedTransportByteCount: dataTransferReport.aggregatePathReport
                .receivedTransportByteCount,
              receivedTransportDuplicateByteCount: dataTransferReport.aggregatePathReport
                .receivedTransportDuplicateByteCount,
              receivedTransportOutOfOrderByteCount: dataTransferReport.aggregatePathReport
                .receivedTransportOutOfOrderByteCount,
              sentTransportByteCount: dataTransferReport.aggregatePathReport.sentTransportByteCount,
              retransmittedTransportByteCount: dataTransferReport.aggregatePathReport
                .retransmittedTransportByteCount,
              transportSmoothedRTT: dataTransferReport.aggregatePathReport.transportSmoothedRTT,
              transportMinimumRTT: dataTransferReport.aggregatePathReport.transportMinimumRTT,
              transportRTTVariance: dataTransferReport.aggregatePathReport.transportRTTVariance,
              receivedApplicationByteCount: dataTransferReport.aggregatePathReport
                .receivedApplicationByteCount,
              sentApplicationByteCount: dataTransferReport.aggregatePathReport
                .sentApplicationByteCount
            ),
            pathReport: .init()
          )
        )
      }
    }
  }
#else

  // TODO: Pending Data Transfer Report non-Darwin
  @available(SwiftStdlib 5.3, *)
  final class PendingDataTransferReport: DataTransferReportCollector {

    init() {}

    @preconcurrency func collect(
      queue: DispatchQueue, completion: @escaping @Sendable (_ report: DataTransferReport) -> Void
    ) {
      completion(.init())
    }
  }
#endif
