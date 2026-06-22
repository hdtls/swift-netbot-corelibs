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
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  /// Information about a process and its associated activity.
  ///
  /// ``V1/ProcessReport`` associates a process identifier with the connection
  /// and application information observed for that process.
  ///
  /// Use this type to correlate network activity with the process and
  /// application that generated it.
  @Model public class ProcessReport {

    /// The identifier of the process.
    ///
    /// This value corresponds to the operating system process identifier (PID)
    /// of the observed process.
    public var processIdentifier: Int32?

    /// The connection associated with the process.
    ///
    /// This value contains information about the network connection that
    /// was attributed to the process.
    public var connection: V1.Connection?

    /// The application associated with the process.
    ///
    /// This value identifies the application to which the process belongs
    /// and provides additional application metadata.
    public var program: V1.Program?

    /// Creates an empty ``V1/ProcessReport`` report.
    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.ProcessReport {

  /// Converts a runtime ``ProcessReport`` into a persistent ``V1/ProcessReport`` snapshot.
  ///
  /// This method captures the current state of the process report at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New `ProcessReport` to map.
  public func mergeValues(_ data: NetbotLiteData.ProcessReport) {
    #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
      if processIdentifier != data.processIdentifier {
        processIdentifier = data.processIdentifier
      }
    #else
      processIdentifier = data.processIdentifier
    #endif
  }
}
