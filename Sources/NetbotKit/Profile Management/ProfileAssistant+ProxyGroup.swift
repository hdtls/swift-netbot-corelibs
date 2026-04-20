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

/// `AnyProxyGroup` management
@available(SwiftStdlib 5.9, *)
extension ProfileAssistant {

  /// Insert new `AnyProxyGroup` item into `ProfileAssistant` managed profile file.
  ///
  /// - Parameter policyGroup: The `AnyProxyGroup` item to insert.
  public func insert(_ policyGroup: AnyProxyGroup) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      if let range = lines.firstRange(match: AnyProxyGroup.sectionRegex) {
        lines.insert(Substring(policyGroup.formatted()), at: range.upperBound)
      } else {
        if lines.last?._trimmingWhitespaces() != "" {
          // Pretty print multiple sections by add an empty line.
          lines.append("")
        }
        lines.append(Substring(AnyProxyGroup.sectionName))
        lines.append(Substring(policyGroup.formatted()))
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Replace `AnyProxyGroup` item `group` with new `AnyProxyGroup` item `newPolicyGroup`.
  ///
  /// - Parameters:
  ///   - group: The original `AnyProxyGroup` item to be replaced.
  ///   - newPolicyGroup: The `AnyProxyGroup` item to replace.
  public func replace(_ group: AnyProxyGroup, with newPolicyGroup: AnyProxyGroup) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines = lines.compactMap { line in
        if !line.matches(of: group.regex).isEmpty {
          return Substring(newPolicyGroup.formatted())
        }

        guard group.name != newPolicyGroup.name else {
          return line
        }

        // Replace group name of owned rules.
        if !line.matches(of: group.rulesRegex).isEmpty {
          return line.replacing(group.name, with: newPolicyGroup.name)
        }

        return line
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Moves all proxy groups at the specified offsets to the specified destination offset, preserving ordering.
  ///
  /// - Parameters:
  ///   - source: An index set representing the offsets of all elements that should be moved.
  ///   - destination: The offset of the element before which to insert the moved elements. `destination` must
  ///     be in the closed range `0...count`.
  public func movePolicyGroups(fromOffsets source: IndexSet, toOffset destination: Int) async throws
  {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex { !$0.matches(of: AnyProxyGroup.regex).isEmpty }
      guard let startIndex else { return }
      let source = IndexSet(source.map({ $0 + startIndex }))
      let destination = destination + startIndex
      lines.move(fromOffsets: source, toOffset: destination)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Removes all proxy groups at the specified offsets from the collection.
  public func removePolicyGroups(atOffsets offsets: IndexSet) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex { !$0.matches(of: AnyProxyGroup.regex).isEmpty }
      guard let startIndex else { return }
      let offsets = IndexSet(offsets.map({ $0 + startIndex }))
      let groups: [AnyProxyGroup] = try offsets.compactMap {
        guard $0 < lines.count else {
          return nil
        }
        return try AnyProxyGroup.FormatStyle().parse(String(lines[$0]))
      }
      lines.remove(atOffsets: offsets)
      lines = lines.compactMap { parseInput in
        groups.contains { !parseInput.matches(of: $0.rulesRegex).isEmpty } ? nil : parseInput
      }

      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Remove `AnyProxyGroup` item from `ProfileAssistant` managed profile file.
  ///
  /// - Parameter policyGroup: The `AnyProxyGroup` item to be removed.
  public func delete(_ policyGroup: AnyProxyGroup) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines = lines.compactMap { parseInput in
        // Remove policy group from `contents`.
        if !parseInput.matches(of: policyGroup.regex).isEmpty {
          return nil
        }
        // Remove associated rules.
        if !parseInput.matches(of: policyGroup.rulesRegex).isEmpty {
          return nil
        }
        return parseInput
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }
}
