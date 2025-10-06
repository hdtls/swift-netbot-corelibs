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

import Testing

@testable import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.dnsMapping, .formatting))
struct DNSMappingFormatStyleTests {

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func formatDNSMapping(_ formatter: DNSMapping.FormatStyle) {
    let formatInput = DNSMapping(domainName: "example.com", value: "1.1.1.1")
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "example.com = 1.1.1.1")
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func formatCNAMEDNSMapping(_ formatter: DNSMapping.FormatStyle) {
    var formatInput = DNSMapping(domainName: "example.com", value: "example1.com")
    formatInput.kind = .cname
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "example.com = example1.com")
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func formatDNSDNSMapping(_ formatter: DNSMapping.FormatStyle) {
    var formatInput = DNSMapping(domainName: "example.com", value: "8.8.8.8")
    formatInput.kind = .dns
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "example.com = server:8.8.8.8")
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func formatDisabledDNSMapping(_ formatter: DNSMapping.FormatStyle) {
    var formatInput = DNSMapping(domainName: "example.com", value: "1.1.1.1")
    formatInput.isEnabled = false
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "# example.com = 1.1.1.1")
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func formatDisabledCNAMEDNSMapping(_ formatter: DNSMapping.FormatStyle) {
    var formatInput = DNSMapping(domainName: "example.com", value: "example1.com")
    formatInput.kind = .cname
    formatInput.isEnabled = false
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "# example.com = example1.com")
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func formatDisabledDNSDNSMapping(_ formatter: DNSMapping.FormatStyle) {
    var formatInput = DNSMapping(domainName: "example.com", value: "8.8.8.8")
    formatInput.kind = .dns
    formatInput.isEnabled = false
    let formatOutput = formatter.format(formatInput)
    #expect(formatOutput == "# example.com = server:8.8.8.8")
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle().parseStrategy,
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func parseDNSMappingFromInvalidString(_ parser: DNSMapping.FormatStyle) {
    let parseFunctions: [(String) throws -> DNSMapping]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      #expect(throws: CocoaError.self) {
        try parse("example.com")
      }
      #expect(throws: CocoaError.self) {
        try parse("example.com = example1.com?query=1")
      }
    }
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle().parseStrategy,
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func parseDNSMapping(_ parser: DNSMapping.FormatStyle) throws {
    let parseInput = "example.com = 1.1.1.1"

    let parseFunctions: [(String) throws -> DNSMapping]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.kind == .mapping)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "1.1.1.1")
      #expect(parseOutput.note == "")
    }
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle().parseStrategy,
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func parseCNAMEDNSMapping(_ parser: DNSMapping.FormatStyle) throws {
    let parseInput = "example.com = example1.com"

    let parseFunctions: [(String) throws -> DNSMapping]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.kind == .cname)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "example1.com")
      #expect(parseOutput.note == "")
    }
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle().parseStrategy,
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func parseDNSDNSMapping(_ parser: DNSMapping.FormatStyle) throws {
    let parseInput = "example.com = server:8.8.8.8"

    let parseFunctions: [(String) throws -> DNSMapping]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.kind == .dns)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "8.8.8.8")
      #expect(parseOutput.note == "")
    }
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle().parseStrategy,
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func parseDisabledDNSMapping(_ parser: DNSMapping.FormatStyle) throws {
    let parseInput = "# example.com = 1.1.1.1"

    let parseFunctions: [(String) throws -> DNSMapping]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.kind == .mapping)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "1.1.1.1")
      #expect(parseOutput.note == "")
    }
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle().parseStrategy,
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func parseDisabledCNAMEDNSMapping(_ parser: DNSMapping.FormatStyle) throws {
    let parseInput = "# example.com = example1.com"

    let parseFunctions: [(String) throws -> DNSMapping]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.kind == .cname)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "example1.com")
      #expect(parseOutput.note == "")
    }
  }

  @Test(arguments: [
    DNSMapping.FormatStyle(),
    DNSMapping.FormatStyle().parseStrategy,
    DNSMapping.FormatStyle.dnsMapping,
  ])
  func parseDisabledDNSDNSMapping(_ parser: DNSMapping.FormatStyle) throws {
    let parseInput = "# example.com = server:8.8.8.8"

    let parseFunctions: [(String) throws -> DNSMapping]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.kind == .dns)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.domainName == "example.com")
      #expect(parseOutput.value == "8.8.8.8")
      #expect(parseOutput.note == "")
    }
  }

  @Test func formatStyleConformance() {
    var formatInput = DNSMapping(domainName: "example.com", value: "8.8.8.8")
    formatInput.kind = .dns
    formatInput.isEnabled = false
    #expect(formatInput.formatted(.dnsMapping) == "# example.com = server:8.8.8.8")
  }

  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try DNSMapping("# example.com = server:8.8.8.8", strategy: .dnsMapping)
    }
  }
}
