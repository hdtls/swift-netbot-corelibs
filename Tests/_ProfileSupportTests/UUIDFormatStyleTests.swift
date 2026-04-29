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

@Suite(.tags(.formatting))
struct UUIDFormatStyleTests {

  let uuid = UUID()

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func uuidFormatStyle() throws {
    let formatInput = uuid
    var formatOutput = formatInput.formatted()
    #expect(formatOutput == uuid.uuidString)

    formatOutput = formatInput.formatted(.uuid)
    #expect(formatOutput == uuid.uuidString)

    formatOutput = UUID.FormatStyle().format(formatInput)
    #expect(formatOutput == uuid.uuidString)

    let parseInput = uuid.uuidString
    var parseOutput = try UUID.FormatStyle().parse(parseInput)
    #expect(parseOutput == uuid)

    parseOutput = try UUID.FormatStyle().parseStrategy.parse(parseInput)
    #expect(parseOutput == uuid)

    parseOutput = try UUID(uuid.uuidString, strategy: .uuid)
    #expect(parseOutput == uuid)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseUUIDFromInvalidString() throws {
    let parseInput = "ABC"
    #expect(throws: CocoaError.self) {
      try UUID.FormatStyle().parse(parseInput)
    }

    #expect(throws: CocoaError.self) {
      try UUID.FormatStyle().parseStrategy.parse(parseInput)
    }

    #expect(throws: CocoaError.self) {
      try UUID(parseInput, strategy: .uuid)
    }
  }

  #if canImport(Darwin)
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func uuidFormatter() throws {
      let formatInput = uuid
      var formatOutput = UUID.Formatter().string(for: formatInput)
      #expect(formatOutput == uuid.uuidString)

      #expect(UUID.Formatter().string(for: "UUID") == nil)
      #expect(UUID.Formatter().string(for: nil) == nil)

      formatOutput = try #require(UUID.Formatter().string(for: .some(formatInput)))
      #expect(formatOutput == uuid.uuidString)

      formatOutput = try #require(UUID.Formatter().string(for: formatInput.uuidString))
      #expect(formatOutput == uuid.uuidString)
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func getObjectValue() {
      let parseInput = "B65361C5-9623-4586-A179-72A40CCE04D5"

      var errorDescription: NSString?
      var parseOutput: AnyObject?
      let formatter = UUID.Formatter()
      var code = formatter.getObjectValue(
        &parseOutput, for: parseInput, errorDescription: &errorDescription)
      #expect(code)
      #expect(parseOutput as? UUID == UUID(uuidString: parseInput))
      #expect(errorDescription == nil)

      parseOutput = nil
      code = formatter.getObjectValue(
        &parseOutput, for: "B65361C5-9623-4586-A179-", errorDescription: &errorDescription)
      #expect(!code)
      #expect(parseOutput == nil)
      #expect(errorDescription != nil)
    }
  #endif
}
