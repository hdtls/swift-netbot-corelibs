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

#if swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData
#endif

@available(SwiftStdlib 5.9, *)
extension V1 {

  #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
    @Model
  #else
    #if swift(>=6.3)
      @Observable
    #endif
  #endif
  public class _ForwardingReport {

    /// The length of time duration on this matching step.
    public var duration: Duration {
      .seconds(_duration)
    }

    /// Length of time in seconds spent on forwarding rule matching.
    public var _duration: Double = 0

    /// Forward protocol used to forward requests.
    public var forwardProtocol = "DIRECT"

    /// Forwarding rule description for establishing connection.
    public var forwardingRule: String?

    public var connection: _Connection?

    public init() {}
  }
}

@available(SwiftStdlib 5.9, *)
extension V1._ForwardingReport {

  /// Merge new values from data transfer object.
  /// - Parameter data: New `ForwardingReport` to merge.
  public func mergeValues(_ data: ForwardingReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
      self._duration = data._duration
      self.forwardingRule = data.forwardingRule
      self.forwardProtocol = data.forwardProtocol
    #else
      if self._duration != data._duration {
        self._duration = data._duration
      }
      if self.forwardingRule != data.forwardingRule {
        self.forwardingRule = data.forwardingRule
      }
      if self.forwardProtocol != data.forwardProtocol {
        self.forwardProtocol = data.forwardProtocol
      }
    #endif
  }
}
