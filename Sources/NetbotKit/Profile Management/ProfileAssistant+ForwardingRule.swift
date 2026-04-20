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

import RegexBuilder
import _ProfileSupport

#if canImport(SwiftUI)
  import Foundation
  import SwiftUI
#else
  import struct Foundation.IndexSet
#endif

/// `AnyForwardingRule` management
@available(SwiftStdlib 5.9, *)
extension ProfileAssistant {

  /// Insert new `AnyForwardingRule` item into `ProfileAssistant` managed profile file.
  ///
  /// - Parameter forwardingRule: The `AnyForwardingRule` item to insert.
  public func insert(_ forwardingRule: AnyForwardingRule) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      if let range = lines.firstRange(match: AnyForwardingRule.sectionRegex) {
        lines.insert(Substring(forwardingRule.formatted()), at: range.lowerBound)
      } else {
        if lines.last?._trimmingWhitespaces() != "" {
          // Pretty print multiple sections by add an empty line.
          lines.append("")
        }
        lines.append(Substring(AnyForwardingRule.sectionName))
        lines.append(Substring(forwardingRule.formatted()))
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Replace `AnyForwardingRule` item `forwardingRule` with new `AnyForwardingRule` item `newRule`.
  ///
  /// - Parameters:
  ///   - forwardingRule: The original `AnyForwardingRule` item to be replaced.
  ///   - newRule: The `AnyForwardingRule` item to replace.
  public func replace(_ forwardingRule: AnyForwardingRule, with newRule: AnyForwardingRule)
    async throws
  {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines = lines.lazy.map {
        if !$0.matches(of: forwardingRule.regex).isEmpty {
          return Substring(newRule.formatted())
        }
        return $0
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Moves all forwarding rules at the specified offsets to the specified destination offset, preserving ordering.
  ///
  /// - Parameters:
  ///   - source: An index set representing the offsets of all elements that should be moved.
  ///   - destination: The offset of the element before which to insert the moved elements. `destination` must
  ///     be in the closed range `0...count`.
  public func moveRules(fromOffsets source: IndexSet, toOffset destination: Int) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex {
        $0.firstMatch(of: AnyForwardingRule.regex) != nil
      }
      guard let startIndex else { return }
      let source = IndexSet(source.map({ $0 + startIndex }))
      let destination = destination + startIndex
      lines.move(fromOffsets: source, toOffset: destination)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Removes all rules at the specified offsets from the collection.
  public func removeRules(atOffsets offsets: IndexSet) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex {
        $0.firstMatch(of: AnyForwardingRule.regex) != nil
      }
      guard let startIndex else { return }
      let offsets = IndexSet(offsets.map({ $0 + startIndex }))
      lines.remove(atOffsets: offsets)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Remove `AnyForwardingRule` item from `ProfileAssistant` managed profile file.
  ///
  /// - Parameter forwardingRule: The `AnyForwardingRule` item to be removed.
  public func delete(_ forwardingRule: AnyForwardingRule) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines.removeAll {
        !$0.matches(of: forwardingRule.regex).isEmpty
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }
}
