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

#if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
  import SwiftData
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1 {

  #if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
    @Model
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
  #endif
  final public class _ProcessReport {

    /// Indicates the process identifier (pid) of the application.
    public var processIdentifier: Int32?

    public var connection: _Connection?

    public var program: _Program?

    public init() {}
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._ProcessReport {

  /// Merge new values from DTO.
  /// - Parameter data: New `ProcessReport` to merge.
  public func mergeValues(_ data: ProcessReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA)
      processIdentifier = data.processIdentifier
    #else
      if processIdentifier != data.processIdentifier {
        processIdentifier = data.processIdentifier
      }
    #endif
  }
}
