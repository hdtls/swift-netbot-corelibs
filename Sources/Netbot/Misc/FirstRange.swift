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

@available(SwiftStdlib 5.7, *)
extension Array where Element == Substring {

  func firstRange(match sectionRegex: some RegexComponent) -> ClosedRange<Int>? {
    guard var start = firstIndex(where: { !$0.matches(of: sectionRegex).isEmpty }) else {
      return nil
    }

    guard start < endIndex else {
      return start...endIndex
    }

    start = index(after: start)
    let slice = suffix(from: start)
    var end = endIndex

    if let endIndex = slice.firstIndex(where: { !$0.matches(of: /^ *\[.+] *$/).isEmpty }) {
      end = endIndex
    }

    // Trimming empty lines.
    while end - 1 >= start {
      guard self[end - 1]._trimmingWhitespaces().isEmpty else {
        break
      }
      end = end - 1
    }

    return start...end
  }
}
