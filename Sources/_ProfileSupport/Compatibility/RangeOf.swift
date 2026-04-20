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
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension String {

    enum _CompareOptions: Sendable {
      case anchored
      case backwards
    }

    func range(of needle: String, options: _CompareOptions = .anchored) -> Range<String.Index>? {
      switch options {
      case .anchored:
        guard !needle.isEmpty, needle.count <= self.count else { return nil }
        var idx = self.startIndex
        while idx <= self.index(self.endIndex, offsetBy: -needle.count) {
          let end = self.index(idx, offsetBy: needle.count)
          if self[idx..<end] == needle {
            return idx..<end
          }
          idx = self.index(after: idx)
        }
        return nil
      case .backwards:
        guard !needle.isEmpty, needle.count <= self.count else { return nil }
        var idx = self.index(self.endIndex, offsetBy: -needle.count)
        while idx >= self.startIndex {
          let end = self.index(idx, offsetBy: needle.count)
          if self[idx..<end] == needle {
            return idx..<end
          }
          if idx == self.startIndex { break }
          idx = self.index(before: idx)
        }
        return nil
      }
    }
  }
#endif
