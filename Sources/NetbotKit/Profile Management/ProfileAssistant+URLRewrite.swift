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

/// `URLRewrite` management
@available(SwiftStdlib 5.9, *)
extension ProfileAssistant {

  /// Insert new `URLRewrite` item into `ProfileAssistant` managed profile file.
  ///
  /// - Parameter urlRewrite: The `URLRewrite` item to insert.
  public func insert(_ urlRewrite: URLRewrite) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      if let range = lines.firstRange(match: URLRewrite.sectionRegex) {
        lines.insert(Substring(urlRewrite.formatted()), at: range.upperBound)
      } else {
        if lines.last?._trimmingWhitespaces() != "" {
          // Pretty print multiple sections by add an empty line.
          lines.append("")
        }
        lines.append(Substring(URLRewrite.sectionName))
        lines.append(Substring(urlRewrite.formatted()))
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Replace `URLRewrite` item `urlRewrite` with new `URLRewrite` item `newURLRewrite`.
  /// - Parameters:
  ///   - urlRewrite: The original `URLRewrite` item to be replaced.
  ///   - newURLRewrite: The `URLRewrite` item to replace.
  public func replace(_ urlRewrite: URLRewrite, with newURLRewrite: URLRewrite) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      let lines =
        string
        .split(separator: .newlineSequence, omittingEmptySubsequences: false)
        .lazy.compactMap { line in
          guard !line.matches(of: urlRewrite.regex).isEmpty else {
            return line
          }
          return Substring(newURLRewrite.formatted())
        }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Moves all URL rewrites at the specified offsets to the specified destination offset, preserving ordering.
  ///
  /// - Parameters:
  ///   - source: An index set representing the offsets of all elements that should be moved.
  ///   - destination: The offset of the element before which to insert the moved elements. `destination` must
  ///     be in the closed range `0...count`.
  public func moveURLRewrites(fromOffsets source: IndexSet, toOffset destination: Int) async throws
  {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex(where: { $0.firstMatch(of: URLRewrite.regex) != nil })
      guard let startIndex else { return }
      let source = IndexSet(source.map({ $0 + startIndex }))
      let destination = destination + startIndex
      lines.move(fromOffsets: source, toOffset: destination)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Removes all URL rewrites at the specified offsets from the collection.
  public func removeURLRewrites(atOffsets offsets: IndexSet) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex(where: { $0.firstMatch(of: URLRewrite.regex) != nil })
      guard let startIndex else { return }
      let offsets = IndexSet(offsets.map({ $0 + startIndex }))
      lines.remove(atOffsets: offsets)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Remove `URLRewrite` item from `ProfileAssistant` managed profile file.
  ///
  /// - Parameter urlRewrite: The `URLRewrite` item to be removed.
  public func delete(_ urlRewrite: URLRewrite) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines.removeAll {
        !$0.matches(of: urlRewrite.regex).isEmpty
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }
}
