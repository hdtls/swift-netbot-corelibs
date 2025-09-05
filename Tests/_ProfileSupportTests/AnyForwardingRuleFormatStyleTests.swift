//
// See LICENSE.txt for license information
//

import Testing

@testable import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.formatting, .forwardingRule))
struct AnyForwardingRuleFormatStyleTests {

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseRuleWithoutComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInput = "DOMAIN,www.swift.org,Auto URL Test"

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.kind == .domain)
      #expect(parseOutput.value == "www.swift.org")
      #expect(parseOutput.foreignKey == "Auto URL Test")
      #expect(parseOutput.comment == "")
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseRuleWithComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInput = "DOMAIN,www.swift.org,Auto URL Test // note..."

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput.isEnabled)
      #expect(parseOutput.kind == .domain)
      #expect(parseOutput.value == "www.swift.org")
      #expect(parseOutput.foreignKey == "Auto URL Test")
      #expect(parseOutput.comment == "note...")
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseDisabledRuleWithoutComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInput = "# DOMAIN,www.swift.org,Auto URL Test"

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.kind == .domain)
      #expect(parseOutput.value == "www.swift.org")
      #expect(parseOutput.foreignKey == "Auto URL Test")
      #expect(parseOutput.comment == "")
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseDisabledRuleWithComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInput = "# DOMAIN,www.swift.org,Auto URL Test // note..."

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(!parseOutput.isEnabled)
      #expect(parseOutput.kind == .domain)
      #expect(parseOutput.value == "www.swift.org")
      #expect(parseOutput.foreignKey == "Auto URL Test")
      #expect(parseOutput.comment == "note...")
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseFinalRuleWithComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInputs = [
      "FINAL,dns-failed,Auto URL Test // test note",
      "FINAL,Auto URL Test // test note",
    ]

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for (offset, parseInput) in parseInputs.enumerated() {
      for parse in parseFunctions {
        let parseOutput = try parse(parseInput)
        #expect(parseOutput.isEnabled)
        #expect(parseOutput.kind == .final)
        #expect(parseOutput.value == (offset == 0 ? "dns-failed" : ""))
        #expect(parseOutput.foreignKey == "Auto URL Test")
        #expect(parseOutput.comment == "test note")
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseFinalRuleWithoutComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInputs = [
      "FINAL,dns-failed,Auto URL Test",
      "FINAL,Auto URL Test",
    ]

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for (offset, parseInput) in parseInputs.enumerated() {
      for parse in parseFunctions {
        let parseOutput = try parse(parseInput)
        #expect(parseOutput.isEnabled)
        #expect(parseOutput.kind == .final)
        #expect(parseOutput.value == (offset == 0 ? "dns-failed" : ""))
        #expect(parseOutput.foreignKey == "Auto URL Test")
        #expect(parseOutput.comment == "")
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseDisabledFinalRuleWithComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInputs = [
      "# FINAL,dns-failed,Auto URL Test // test note",
      "# FINAL,Auto URL Test // test note",
    ]

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for (offset, parseInput) in parseInputs.enumerated() {
      for parse in parseFunctions {
        let parseOutput = try parse(parseInput)
        #expect(!parseOutput.isEnabled)
        #expect(parseOutput.kind == .final)
        #expect(parseOutput.value == (offset == 0 ? "dns-failed" : ""))
        #expect(parseOutput.foreignKey == "Auto URL Test")
        #expect(parseOutput.comment == "test note")
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseDisabledFinalRuleWithoutComment(_ parser: AnyForwardingRule.FormatStyle) throws {
    let parseInputs = [
      "# FINAL,dns-failed,Auto URL Test",
      "# FINAL,Auto URL Test",
    ]

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for (offset, parseInput) in parseInputs.enumerated() {
      for parse in parseFunctions {
        let parseOutput = try parse(parseInput)
        #expect(!parseOutput.isEnabled)
        #expect(parseOutput.kind == .final)
        #expect(parseOutput.value == (offset == 0 ? "dns-failed" : ""))
        #expect(parseOutput.foreignKey == "Auto URL Test")
        #expect(parseOutput.comment == "")
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseRuleWithExtraWhitespaces(_ parser: AnyForwardingRule.FormatStyle) throws {
    let collection = [
      "   DOMAIN,www.swift.org,Auto URL Test",
      "DOMAIN,  www.swift.org, Auto URL Test // test note",
      "#   DOMAIN, www.swift.org,Auto URL Test",
      "# DOMAIN,www.swift.org,   Auto URL Test // test note",
    ]

    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for (offset, parseInput) in collection.enumerated() {
      for parse in parseFunctions {
        let parseOutput = try parse(parseInput)
        #expect(parseOutput.isEnabled == (offset > 1 ? false : true))
        #expect(parseOutput.kind == .domain)
        #expect(parseOutput.value == "www.swift.org")
        #expect(parseOutput.foreignKey == "Auto URL Test")
        #expect(parseOutput.comment == (offset % 2 == 0 ? "" : "test note"))
      }
    }

    for parse in parseFunctions {
      let parseOutput = try parse("FINAL,Auto URL Test // test note    ")
      #expect(parseOutput.isEnabled == true)
      #expect(parseOutput.kind == .final)
      #expect(parseOutput.value == "")
      #expect(parseOutput.foreignKey == "Auto URL Test")
      #expect(parseOutput.comment == "test note")
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle().parseStrategy,
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func parseRuleContainsUnknownTypes(_ parser: AnyForwardingRule.FormatStyle) {
    let parseFunctions: [(String) throws -> AnyForwardingRule]
    if #available(SwiftStdlib 5.5, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      #expect(throws: CocoaError.self) {
        try parse("UNKNOWN,swift.org,Auto URL Test")
      }

      #expect(throws: CocoaError.self) {
        try parse("# UNKNOWN,swift.org,Auto URL Test")
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try AnyForwardingRule("GEOIP, CN, direct", strategy: .forwardingRule)
    }
  }

  @Test(arguments: [
    AnyForwardingRule.FormatStyle(),
    AnyForwardingRule.FormatStyle.forwardingRule,
  ])
  func formatRule(_ formatter: AnyForwardingRule.FormatStyle) {
    var forwardingRule = AnyForwardingRule()
    var formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "DOMAIN, , DIRECT")

    forwardingRule = AnyForwardingRule()
    forwardingRule.foreignKey = "Auto URL Test"
    forwardingRule.kind = .domainSuffix
    forwardingRule.value = "swift.org"
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "DOMAIN-SUFFIX, swift.org, Auto URL Test")

    forwardingRule = AnyForwardingRule()
    forwardingRule.foreignKey = "Auto URL Test"
    forwardingRule.kind = .domainSuffix
    forwardingRule.value = "swift.org"
    forwardingRule.comment = "test note"
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "DOMAIN-SUFFIX, swift.org, Auto URL Test // test note")

    forwardingRule = AnyForwardingRule()
    forwardingRule.foreignKey = "Auto URL Test"
    forwardingRule.isEnabled = false
    forwardingRule.kind = .domainSuffix
    forwardingRule.value = "swift.org"
    forwardingRule.comment = "test note"
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "# DOMAIN-SUFFIX, swift.org, Auto URL Test // test note")

    // Missing policy or policy group value
    forwardingRule = AnyForwardingRule()
    forwardingRule.kind = .final
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "FINAL, DIRECT")

    forwardingRule = AnyForwardingRule()
    forwardingRule.foreignKey = "Auto URL Test"
    forwardingRule.kind = .final
    forwardingRule.value = "dns-failed"
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "FINAL, dns-failed, Auto URL Test")

    forwardingRule = AnyForwardingRule()
    forwardingRule.foreignKey = "Auto URL Test"
    forwardingRule.kind = .final
    forwardingRule.value = ""
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "FINAL, Auto URL Test")

    forwardingRule = AnyForwardingRule()
    forwardingRule.foreignKey = "Auto URL Test"
    forwardingRule.isEnabled = false
    forwardingRule.kind = .final
    forwardingRule.value = "dns-failed"
    forwardingRule.comment = "test note"
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "# FINAL, dns-failed, Auto URL Test // test note")

    forwardingRule = AnyForwardingRule()
    forwardingRule.foreignKey = "Auto URL Test"
    forwardingRule.isEnabled = false
    forwardingRule.kind = .final
    forwardingRule.value = ""
    forwardingRule.comment = "test note"
    formatOutput = formatter.format(forwardingRule)
    #expect(formatOutput == "# FINAL, Auto URL Test // test note")

    formatOutput = forwardingRule.formatted()
    #expect(formatOutput == "# FINAL, Auto URL Test // test note")

    formatOutput = forwardingRule.formatted(.forwardingRule)
    #expect(formatOutput == "# FINAL, Auto URL Test // test note")
  }

  @Test func formatStyleConformance() {
    var formatInput = AnyForwardingRule()
    formatInput.kind = .geoip
    formatInput.value = "CN"
    formatInput.isEnabled = false
    #expect(formatInput.formatted(.forwardingRule) == "# GEOIP, CN, DIRECT")
  }
}
