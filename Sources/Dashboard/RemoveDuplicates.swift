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

@available(SwiftStdlib 5.3, *)
extension Sequence where Element: Hashable {

  /// Return the sequence with all duplicates removed.
  ///
  /// i.e. `[ 1, 2, 3, 1, 2 ].removeDuplicates() == [ 1, 2, 3 ]`
  public func removeDuplicates() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}
