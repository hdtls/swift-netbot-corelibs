//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  public import Foundation
  private import SwiftUI
#else
  public import _FoundationEssentials
#endif

/// `DNS` management
@available(swift 5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension ProfileAssistant {

  /// Remove specified DNS server.
  public func removeDNSServer(_ server: String) async throws {
    try await modify { readIntent, writeIntent in
      var contents = try String(contentsOf: readIntent.url, encoding: .utf8)
      contents.replace(/\ *dns-servers *=.+/) {
        $0.output.replacing("\(server), ", with: "").replacing(server, with: "")
      }
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Remove DNS servers at specified offsets.
  public func removeDNSServers(atOffsets offsets: IndexSet) async throws {
    try await modify { readIntent, writeIntent in
      var contents = try String(contentsOf: readIntent.url, encoding: .utf8)
      contents.replace(/\ *dns-servers *= *(.+)/) {
        var servers = $0.output.1.split(separator: /, */)
        servers.remove(atOffsets: offsets)
        return "dns-servers = " + servers.joined(separator: ", ")
      }
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Insert new `DNSMapping` item into `ProfileAssistant` managed profile file.
  ///
  /// - Parameter dnsMapping: The `DNSMapping` item to insert.
  public func insert(_ dnsMapping: DNSMapping) async throws {
    try await modify { readIntent, writeIntent in
      let file = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = file.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      if let range = lines.firstRange(match: DNSMapping.sectionRegex) {
        lines.insert(Substring(dnsMapping.formatted()), at: range.upperBound)
      } else {
        if lines.last?.trimmingCharacters(in: .whitespaces) != "" {
          // Pretty print multiple sections by add an empty line.
          lines.append("")
        }
        lines.append(Substring(DNSMapping.sectionName))
        lines.append(Substring(dnsMapping.formatted()))
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Replace `DNSMapping` item `dnsMapping` with new `DNSMapping` item `newDNSMapping`.
  ///
  /// - Parameters:
  ///   - dnsMapping: The original `DNSMapping` item to be replaced.
  ///   - newDNSMapping: The `DNSMapping` item to replace.
  public func replace(_ dnsMapping: DNSMapping, with newDNSMapping: DNSMapping) async throws {
    try await modify { readIntent, writeIntent in
      let file = try String(contentsOf: readIntent.url, encoding: .utf8)
      let lines = file.split(separator: .newlineSequence, omittingEmptySubsequences: false)
        .lazy.compactMap { line in
          guard !line.matches(of: dnsMapping.buildAsRegex()).isEmpty else {
            return line
          }
          return Substring(newDNSMapping.formatted())
        }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  /// Remove `DNSMapping` item from `ProfileAssistant` managed profile file.
  ///
  /// - Parameter dnsMapping: The `DNSMapping` item to be removed.
  public func delete(_ dnsMapping: DNSMapping) async throws {
    try await modify { readIntent, writeIntent in
      let file = try String(contentsOf: readIntent.url, encoding: .utf8)
      var lines = file.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      lines.removeAll {
        !$0.matches(of: dnsMapping.buildAsRegex()).isEmpty
      }
      let contents = lines.joined(separator: "\n")
      try contents.write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }
}
