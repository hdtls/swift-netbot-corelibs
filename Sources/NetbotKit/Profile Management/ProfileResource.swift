// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Combine)
  import Combine
#else
  import OpenCombine
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct ProfileInfo: Equatable, Hashable, Identifiable, Sendable {

  public var id: URL { url }

  public var url: URL

  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }

  public var numberOfRules: Int

  public var numberOfProxies: Int
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@MainActor final public class ProfileResource: ObservableObject {

  @Published public var profiles: [ProfileInfo] = []

  nonisolated internal init() {

  }
}
