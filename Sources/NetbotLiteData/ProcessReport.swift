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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct ProcessReport: Codable, Hashable, Sendable {

  /// Indicates the process identifier (pid) of the application.
  public var processIdentifier: Int32?

  public var program: Program?

  public init(processIdentifier: Int32? = nil, program: Program? = nil) {
    self.processIdentifier = processIdentifier
    self.program = program
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ProcessReport {

  public typealias Model = V1._ProcessReport

  public init(persistentModel: Model) {
    processIdentifier = persistentModel.processIdentifier
  }
}
