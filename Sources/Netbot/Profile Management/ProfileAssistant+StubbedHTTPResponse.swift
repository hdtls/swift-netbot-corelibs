//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

#if canImport(SwiftUI)
  import Foundation
  import SwiftUI
#else
  import struct Foundation.IndexSet
#endif

/// `StubbedHTTPResponse` management
@available(swift 5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension ProfileAssistant {

  /// Insert new `StubbedHTTPResponse` item into `ProfileAssistant` managed profile file.
  ///
  /// - Parameter stubbedHTTPResponse: The `StubbedHTTPResponse` item to insert.
  public func insert(_ stubbedHTTPResponse: StubbedHTTPResponse) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      if let range = lines.firstRange(match: StubbedHTTPResponse.sectionRegex) {
        lines.insert(Substring(stubbedHTTPResponse.formatted()), at: range.upperBound)
      } else {
        if lines.last?._trimmingWhitespaces() != "" {
          // Pretty print multiple sections by add an empty line.
          lines.append("")
        }
        lines.append(Substring(StubbedHTTPResponse.sectionName))
        lines.append(Substring(stubbedHTTPResponse.formatted()))
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Replace `StubbedHTTPResponse` item `httpResponseMock` with new `StubbedHTTPResponse` item `newHTTPResponseMock`.
  /// - Parameters:
  ///   - stubbedHTTPResponse: The original `StubbedHTTPResponse` item to be replaced.
  ///   - newStubbedHTTPResponse: The `StubbedHTTPResponse` item to replace.
  public func replace(
    _ stubbedHTTPResponse: StubbedHTTPResponse, with newStubbedHTTPResponse: StubbedHTTPResponse
  ) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      let lines =
        string
        .split(separator: .newlineSequence, omittingEmptySubsequences: false)
        .lazy.compactMap { line in
          guard !line.matches(of: stubbedHTTPResponse.buildAsRegex()).isEmpty else {
            return line
          }
          return Substring(newStubbedHTTPResponse.formatted())
        }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Moves all stubbed responses at the specified offsets to the specified destination offset, preserving ordering.
  ///
  /// - Parameters:
  ///   - source: An index set representing the offsets of all elements that should be moved.
  ///   - destination: The offset of the element before which to insert the moved elements. `destination` must
  ///     be in the closed range `0...count`.
  public func moveStubbedHTTPResponses(fromOffsets source: IndexSet, toOffset destination: Int)
    async throws
  {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex(where: {
        $0.firstMatch(of: StubbedHTTPResponse.regex) != nil
      }
      )
      guard let startIndex else { return }
      let source = IndexSet(source.map({ $0 + startIndex }))
      let destination = destination + startIndex
      lines.move(fromOffsets: source, toOffset: destination)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Removes all stubbed response at the specified offsets from the collection.
  public func removeStubbedHTTPResponses(atOffsets offsets: IndexSet) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex(where: {
        $0.firstMatch(of: StubbedHTTPResponse.regex) != nil
      }
      )
      guard let startIndex else { return }
      let offsets = IndexSet(offsets.map({ $0 + startIndex }))
      lines.remove(atOffsets: offsets)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Remove `StubbedHTTPResponse` item from `ProfileAssistant` managed profile file.
  ///
  /// - Parameter stubbedHTTPResponse: The `StubbedHTTPResponse` item to be removed.
  public func delete(_ stubbedHTTPResponse: StubbedHTTPResponse) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines.removeAll {
        !$0.matches(of: stubbedHTTPResponse.buildAsRegex()).isEmpty
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }
}
