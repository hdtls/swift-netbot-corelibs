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

import NetbotProfile

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
extension Profile {
  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }
}

#if canImport(SwiftData)
  @available(SwiftStdlib 6.0, *)
  extension Profile.Model {
    public var name: String {
      url.deletingPathExtension().lastPathComponent
    }
  }
#endif
