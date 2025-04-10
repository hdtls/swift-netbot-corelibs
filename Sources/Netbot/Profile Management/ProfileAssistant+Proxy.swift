//
// See LICENSE.txt for license information
//

import _ResourceProcessing
#if canImport(SwiftUI)
  import Foundation
  import SwiftUI
#else
  import struct Foundation.IndexSet
#endif

/// `AnyProxy` management
@available(swift 5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension ProfileAssistant {

  /// Insert new `AnyProxy` item into `ProfileAssistant` managed profile file.
  ///
  /// - Parameter proxy: The `AnyProxy` item to insert.
  public func insert(_ proxy: AnyProxy) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      if let range = lines.firstRange(match: AnyProxy.sectionRegex) {
        lines.insert(Substring(proxy.formatted()), at: range.upperBound)
      } else {
        if lines.last?.trimmingCharacters(in: .whitespaces) != "" {
          // Pretty print multiple sections by add an empty line.
          lines.append("")
        }
        lines.append(Substring(AnyProxy.sectionName))
        lines.append(Substring(proxy.formatted()))
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Replace `AnyProxy` item `proxy` with new `AnyProxy` item `newProxy`.
  ///
  /// - Parameters:
  ///   - proxy: The original `AnyProxy` item to be replaced.
  ///   - newProxy: The `AnyProxy` item to replace.
  public func replace(_ proxy: AnyProxy, with newProxy: AnyProxy) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines = lines.compactMap { line in
        if !line.matches(of: proxy.buildAsRegex()).isEmpty {
          return Substring(newProxy.formatted())
        }
        // If name changed, we need also update associated rules and groups.
        guard proxy.name != newProxy.name else {
          return line
        }

        // Replace policy name of owned rules.
        if !line.matches(of: proxy.ownedRulesRegex).isEmpty {
          return line.replacing(proxy.name, with: newProxy.name)
        }

        // Replace policy listed in policy group.
        guard let g = line.firstMatch(of: AnyProxyGroup.regex) else {
          return line
        }
        guard let parseOutput = g.3.firstMatch(of: /\ *proxies *= *(.+)/) else {
          // DO NOTHING if policy group contains external resource.
          return line
        }
        var proxies = parseOutput.1.split(separator: ",").map { $0.trimmingWhitespaces() }
        if proxies.contains(proxy.name) {
          proxies.replace(CollectionOfOne(proxy.name), with: CollectionOfOne(newProxy.name))
          let name = g.1.trimmingWhitespaces()
          return "\(name) = \(g.2.rawValue), proxies = \(proxies.joined(separator: ", "))"
        }
        return line
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Moves all proxies at the specified offsets to the specified destination offset, preserving ordering.
  ///
  /// - Parameters:
  ///   - source: An index set representing the offsets of all elements that should be moved.
  ///   - destination: The offset of the element before which to insert the moved elements. `destination` must
  ///     be in the closed range `0...count`.
  public func moveProxies(fromOffsets source: IndexSet, toOffset destination: Int) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex(where: { $0.firstMatch(of: AnyProxy.regex) != nil })
      guard let startIndex else { return }
      let source = IndexSet(source.map({ $0 + startIndex }))
      let destination = destination + startIndex
      lines.move(fromOffsets: source, toOffset: destination)
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Removes all proxies at the specified offsets from the collection.
  public func removeProxies(atOffsets offsets: IndexSet) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      let startIndex = lines.firstIndex(where: { $0.firstMatch(of: AnyProxy.regex) != nil })
      guard let startIndex else { return }
      let offsets = IndexSet(offsets.map({ $0 + startIndex }))

      let policies: [AnyProxy] = try offsets.compactMap {
        guard $0 < lines.count else {
          return nil
        }
        return try AnyProxy.FormatStyle().parse(String(lines[$0]))
      }

      lines.remove(atOffsets: offsets)

      lines = lines.compactMap { parseInput in
        for policy in policies {
          // Remove associated rules.
          if parseInput.firstMatch(of: policy.ownedRulesRegex) != nil {
            return nil
          }
          guard let g = parseInput.firstMatch(of: AnyProxyGroup.regex) else {
            continue
          }
          guard let parseOutput = g.3.firstMatch(of: /\ *proxies *= *(.+)/) else {
            // DO NOTHING if policy group contains external resource.
            continue
          }
          var policies = parseOutput.1.split(separator: ",").map { $0.trimmingWhitespaces() }
          if policies.contains(policy.name) {
            policies.removeAll(where: { $0 == policy.name })
            let name = g.1.trimmingCharacters(in: .whitespaces)
            return "\(name) = \(g.2.rawValue), proxies = \(policies.joined(separator: ", "))"
          }
        }
        return parseInput
      }

      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Remove `AnyProxy` item from `ProfileAssistant` managed profile file.
  ///
  /// - Parameter proxy: The `AnyProxy` item to be removed.
  public func delete(_ proxy: AnyProxy) async throws {
    try await modify { readIntent, writeIntent in
      let string = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = string.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines = lines.compactMap { parseInput in
        // Remove policy from `contents`.
        if parseInput.firstMatch(of: proxy.buildAsRegex()) != nil {
          return nil
        }

        // Remove associated rules.
        if parseInput.firstMatch(of: proxy.ownedRulesRegex) != nil {
          return nil
        }

        if let parseOutput = parseInput.firstMatch(of: AnyProxyGroup.regex) {
          var proxies = parseOutput.3.split(separator: ",").map { $0.trimmingWhitespaces() }
          if proxies.contains(proxy.name) {
            guard proxies.count > 1 else {
              // Remove proxy group that does not contains any proxy.
              return nil
            }
            proxies.removeAll(where: { $0 == proxy.name })
            return
              "\(parseOutput.1.trimmingWhitespaces()) = \(parseOutput.2.rawValue), proxies = \(proxies.joined(separator: ", "))"
          }
        }

        return parseInput
      }

      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }
}
