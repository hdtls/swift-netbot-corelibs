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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

@available(SwiftStdlib 6.0, *)
public struct ProfileInfo: Hashable, Identifiable, Sendable {

  public var id: URL { url }

  public let url: URL

  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }

  public let numberOfRules: Int

  public let numberOfProxies: Int
}

@available(SwiftStdlib 6.0, *)
#if canImport(Darwin) || swift(>=6.3)
  @Observable
#endif
@MainActor final public class ProfileResource {

  public var profiles: [ProfileInfo] = []

  nonisolated internal init() {

  }
}
