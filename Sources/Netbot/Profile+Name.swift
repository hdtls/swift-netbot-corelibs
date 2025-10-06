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

import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension Profile {
  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }
}

#if canImport(SwiftData)
  @available(SwiftStdlib 5.9, *)
  extension Profile.PersistentModel {
    public var name: String {
      url.deletingPathExtension().lastPathComponent
    }
  }
#endif
