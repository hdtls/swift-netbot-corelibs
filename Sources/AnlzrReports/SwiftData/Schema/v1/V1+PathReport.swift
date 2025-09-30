//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if swift(>=6.3) || canImport(Darwin)
  import Observation

  #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
    import SwiftData
  #endif

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    /// A path report contains counters and statistics observed
    /// by the connection along a single network path.
    @available(SwiftStdlib 5.9, *)
    #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
      @Model
    #else
      @Observable
    #endif
    public class _PathReport {

      /// The number of IP packets received.
      public var receivedIPPacketCount: UInt64 = 0

      /// The number of IP packets sent.
      public var sentIPPacketCount: UInt64 = 0

      /// The number of transport protocol bytes (such as TCP stream bytes) received.
      public var receivedTransportByteCount: UInt64 = 0

      /// The number of transport protocol bytes received as duplicates.
      public var receivedTransportDuplicateByteCount: UInt64 = 0

      /// The number of transport protocol bytes received out of order.
      public var receivedTransportOutOfOrderByteCount: UInt64 = 0

      /// The number of transport protocol bytes (such as TCP stream bytes) sent.
      public var sentTransportByteCount: UInt64 = 0

      /// The number of transport protocol bytes retransmitted as part of loss recovery.
      public var retransmittedTransportByteCount: UInt64 = 0

      /// The smoothed average of the transport protocol's round trip time, in seconds.
      public var transportSmoothedRTT: Double = 0

      /// The minimum value of the transport protocol's round trip time, in seconds.
      public var transportMinimumRTT: Double = 0

      /// The variance of the transport protocol's round trip time.
      public var transportRTTVariance: Double = 0

      /// The number of bytes received by the application.
      public var receivedApplicationByteCount: UInt64 = 0

      /// The number of bytes sent by the application.
      public var sentApplicationByteCount: UInt64 = 0

      public var dataTransferReport: _DataTransferReport?

      public init() {}
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._PathReport {

    public func mergeValues(_ data: DataTransferReport.PathReport) {
      #if swift(>=6.2) && !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
        self.receivedIPPacketCount = data.receivedIPPacketCount
        self.sentIPPacketCount = data.sentIPPacketCount
        self.receivedTransportByteCount = data.receivedTransportByteCount
        self.receivedTransportDuplicateByteCount = data.receivedTransportDuplicateByteCount
        self.receivedTransportOutOfOrderByteCount = data.receivedTransportOutOfOrderByteCount
        self.sentTransportByteCount = data.sentTransportByteCount
        self.retransmittedTransportByteCount = data.retransmittedTransportByteCount
        self.transportSmoothedRTT = data.transportSmoothedRTT
        self.transportMinimumRTT = data.transportMinimumRTT
        self.transportRTTVariance = data.transportRTTVariance
        self.receivedApplicationByteCount = data.receivedApplicationByteCount
        self.sentApplicationByteCount = data.sentApplicationByteCount
      #else
        if self.receivedIPPacketCount != data.receivedIPPacketCount {
          self.receivedIPPacketCount = data.receivedIPPacketCount
        }
        if self.sentIPPacketCount != data.sentIPPacketCount {
          self.sentIPPacketCount = data.sentIPPacketCount
        }
        if self.receivedTransportByteCount != data.receivedTransportByteCount {
          self.receivedTransportByteCount = data.receivedTransportByteCount
        }
        if self.receivedTransportDuplicateByteCount != data.receivedTransportDuplicateByteCount {
          self.receivedTransportDuplicateByteCount = data.receivedTransportDuplicateByteCount
        }
        if self.receivedTransportOutOfOrderByteCount != data.receivedTransportOutOfOrderByteCount {
          self.receivedTransportOutOfOrderByteCount = data.receivedTransportOutOfOrderByteCount
        }
        if self.sentTransportByteCount != data.sentTransportByteCount {
          self.sentTransportByteCount = data.sentTransportByteCount
        }
        if self.retransmittedTransportByteCount != data.retransmittedTransportByteCount {
          self.retransmittedTransportByteCount = data.retransmittedTransportByteCount
        }
        if self.transportSmoothedRTT != data.transportSmoothedRTT {
          self.transportSmoothedRTT = data.transportSmoothedRTT
        }
        if self.transportMinimumRTT != data.transportMinimumRTT {
          self.transportMinimumRTT = data.transportMinimumRTT
        }
        if self.transportRTTVariance != data.transportRTTVariance {
          self.transportRTTVariance = data.transportRTTVariance
        }
        if self.receivedApplicationByteCount != data.receivedApplicationByteCount {
          self.receivedApplicationByteCount = data.receivedApplicationByteCount
        }
        if self.sentApplicationByteCount != data.sentApplicationByteCount {
          self.sentApplicationByteCount = data.sentApplicationByteCount
        }
      #endif
    }
  }
#endif
