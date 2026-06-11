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

@available(SwiftStdlib 6.0, *)
extension Sequence where Element: Hashable {

  /// Return the sequence with all duplicates removed.
  ///
  /// i.e. `[ 1, 2, 3, 1, 2 ].removeDuplicates() == [ 1, 2, 3 ]`
  public func removeDuplicates() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}
