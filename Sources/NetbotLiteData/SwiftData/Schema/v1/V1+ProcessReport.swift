// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
  import SwiftData
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._ProcessReport {

  /// Merge new values from data transfer object.
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
