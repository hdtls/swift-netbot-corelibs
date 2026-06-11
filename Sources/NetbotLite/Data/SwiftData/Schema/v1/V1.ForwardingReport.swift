// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    @Model public class _ForwardingReport {

      /// The length of time duration on this matching step.
      @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
      public var duration: Duration = Duration.zero

      /// Forward protocol used to forward requests.
      public var forwardProtocol = "DIRECT"

      /// Forwarding rule description for establishing connection.
      public var forwardingRule: String?

      public var connection: _Connection?

      public init() {}
    }
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    public class _ForwardingReport {

      /// The length of time duration on this matching step.
      public var duration: Duration = Duration.zero

      /// Forward protocol used to forward requests.
      public var forwardProtocol = "DIRECT"

      /// Forwarding rule description for establishing connection.
      public var forwardingRule: String?

      public var connection: _Connection?

      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1._ForwardingReport {

  /// Merge new values from DTO.
  /// - Parameter data: New `ForwardingReport` to merge.
  public func mergeValues(_ data: ForwardingReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.duration = data.duration
      self.forwardingRule = data.forwardingRule
      self.forwardProtocol = data.forwardProtocol
    #else
      if self.duration != data.duration {
        self.duration = data.duration
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
