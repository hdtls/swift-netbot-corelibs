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

import Testing

@testable import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.dnsMapping, .formatting))
struct ProtocolDNS_Mapping_FormatStyleTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func formatDNSMapping(_ formatter: ProtocolDNS.Mapping.FormatStyle) {
    let formatInput = ProtocolDNS.Mapping(domainName: "example.com", value: "1.1.1.1")
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "example.com = 1.1.1.1")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func formatCNAMEDNSMapping(_ formatter: ProtocolDNS.Mapping.FormatStyle) {
    var formatInput = ProtocolDNS.Mapping(domainName: "example.com", value: "example1.com")
    formatInput.strategy = .cname
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "example.com = example1.com")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func formatDNSDNSMapping(_ formatter: ProtocolDNS.Mapping.FormatStyle) {
    var formatInput = ProtocolDNS.Mapping(domainName: "example.com", value: "8.8.8.8")
    formatInput.strategy = .dns
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "example.com = server:8.8.8.8")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func formatDisabledDNSMapping(_ formatter: ProtocolDNS.Mapping.FormatStyle) {
    var formatInput = ProtocolDNS.Mapping(domainName: "example.com", value: "1.1.1.1")
    formatInput.isEnabled = false
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "# example.com = 1.1.1.1")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func formatDisabledCNAMEDNSMapping(_ formatter: ProtocolDNS.Mapping.FormatStyle) {
    var formatInput = ProtocolDNS.Mapping(domainName: "example.com", value: "example1.com")
    formatInput.strategy = .cname
    formatInput.isEnabled = false
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "# example.com = example1.com")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func formatDisabledDNSDNSMapping(_ formatter: ProtocolDNS.Mapping.FormatStyle) {
    var formatInput = ProtocolDNS.Mapping(domainName: "example.com", value: "8.8.8.8")
    formatInput.strategy = .dns
    formatInput.isEnabled = false
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "# example.com = server:8.8.8.8")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle().parseStrategy,
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func parseDNSMappingFromInvalidString(_ parser: ProtocolDNS.Mapping.FormatStyle) {
    let parseFunctions: [(String) throws -> ProtocolDNS.Mapping]
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.5, *) {
        parseFunctions = [parser.parse, parser._parse, parser._parse0]
      } else {
        parseFunctions = [parser.parse, parser._parse0]
      }
    #else
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    #endif

    for parse in parseFunctions {
      #expect(throws: CocoaError.self) {
        try parse("example.com")
      }
      #expect(throws: CocoaError.self) {
        try parse("example.com = example1.com?query=1")
      }
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle().parseStrategy,
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func parseDNSMapping(_ parser: ProtocolDNS.Mapping.FormatStyle) throws {
    let parseInput = "example.com = 1.1.1.1"

    let parseFunctions: [(String) throws -> ProtocolDNS.Mapping]
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.5, *) {
        parseFunctions = [parser.parse, parser._parse, parser._parse0]
      } else {
        parseFunctions = [parser.parse, parser._parse0]
      }
    #else
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    #endif

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.strategy == .mapping)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "1.1.1.1")
      #expect(parseOutput.note == "")
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle().parseStrategy,
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func parseCNAMEDNSMapping(_ parser: ProtocolDNS.Mapping.FormatStyle) throws {
    let parseInput = "example.com = example1.com"

    let parseFunctions: [(String) throws -> ProtocolDNS.Mapping]
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.5, *) {
        parseFunctions = [parser.parse, parser._parse, parser._parse0]
      } else {
        parseFunctions = [parser.parse, parser._parse0]
      }
    #else
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    #endif

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.strategy == .cname)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "example1.com")
      #expect(parseOutput.note == "")
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle().parseStrategy,
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func parseDNSDNSMapping(_ parser: ProtocolDNS.Mapping.FormatStyle) throws {
    let parseInput = "example.com = server:8.8.8.8"

    let parseFunctions: [(String) throws -> ProtocolDNS.Mapping]
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.5, *) {
        parseFunctions = [parser.parse, parser._parse, parser._parse0]
      } else {
        parseFunctions = [parser.parse, parser._parse0]
      }
    #else
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    #endif

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.strategy == .dns)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "8.8.8.8")
      #expect(parseOutput.note == "")
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle().parseStrategy,
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func parseDisabledDNSMapping(_ parser: ProtocolDNS.Mapping.FormatStyle) throws {
    let parseInput = "# example.com = 1.1.1.1"

    let parseFunctions: [(String) throws -> ProtocolDNS.Mapping]
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.5, *) {
        parseFunctions = [parser.parse, parser._parse, parser._parse0]
      } else {
        parseFunctions = [parser.parse, parser._parse0]
      }
    #else
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    #endif

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.strategy == .mapping)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "1.1.1.1")
      #expect(parseOutput.note == "")
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle().parseStrategy,
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func parseDisabledCNAMEDNSMapping(_ parser: ProtocolDNS.Mapping.FormatStyle) throws {
    let parseInput = "# example.com = example1.com"

    let parseFunctions: [(String) throws -> ProtocolDNS.Mapping]
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.5, *) {
        parseFunctions = [parser.parse, parser._parse, parser._parse0]
      } else {
        parseFunctions = [parser.parse, parser._parse0]
      }
    #else
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    #endif
    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.strategy == .cname)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "example1.com")
      #expect(parseOutput.note == "")
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ProtocolDNS.Mapping.FormatStyle(),
    ProtocolDNS.Mapping.FormatStyle().parseStrategy,
    ProtocolDNS.Mapping.FormatStyle.dnsMapping,
  ])
  func parseDisabledDNSDNSMapping(_ parser: ProtocolDNS.Mapping.FormatStyle) throws {
    let parseInput = "# example.com = server:8.8.8.8"

    let parseFunctions: [(String) throws -> ProtocolDNS.Mapping]
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.5, *) {
        parseFunctions = [parser.parse, parser._parse, parser._parse0]
      } else {
        parseFunctions = [parser.parse, parser._parse0]
      }
    #else
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    #endif

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.strategy == .dns)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "8.8.8.8")
      #expect(parseOutput.note == "")
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func formatStyleConformance() {
    var formatInput = ProtocolDNS.Mapping(domainName: "example.com", value: "8.8.8.8")
    formatInput.strategy = .dns
    formatInput.isEnabled = false
    #expect(formatInput.formatted(.dnsMapping) == "# example.com = server:8.8.8.8")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try ProtocolDNS.Mapping("# example.com = server:8.8.8.8", strategy: .dnsMapping)
    }
  }
}
