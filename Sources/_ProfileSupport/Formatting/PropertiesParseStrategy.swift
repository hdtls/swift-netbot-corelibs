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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
struct PropertiesParseStrategy {

  func parse(_ parseInput: String) throws -> [String: [String]] {
    if #available(SwiftStdlib 5.7, *) {
      try _parse(parseInput)
    } else {
      try _parse0(parseInput)
    }
  }

  @available(SwiftStdlib 5.7, *)
  func _parse(_ parseInput: String) throws -> [String: [String]] {
    var properties: [String: [String]] = [:]
    var parseInput = Substring(parseInput)

    var replaced: [Substring: String] = [:]

    parseInput.replace(/".*"/.repetitionBehavior(.reluctant)) { match in
      let key = Date.timeIntervalSinceReferenceDate
      replaced["__TEMP_\(key)"] = match.output.replacing(/\"/, with: "")._trimmingWhitespaces()
      return "__TEMP_\(key)"
    }

    var sequence = parseInput.split(whereSeparator: { $0 == "=" })

    while !sequence.isEmpty {
      // First element should always represent as property label field.
      let label = sequence.removeFirst()._trimmingWhitespaces()
      guard !label.contains(",") else {
        throw CocoaError(.formatting)
      }

      // If sequence is empty then we can mark it as missing value field.
      guard !sequence.isEmpty else {
        throw CocoaError(.formatting)
      }
      let value = sequence.removeFirst()._trimmingWhitespaces()
      var values = value.split(whereSeparator: { $0 == "," }).map {
        $0._trimmingWhitespaces()
      }

      guard values.count > 1, !sequence.isEmpty else {
        properties[label] = values.map {
          return replaced[Substring($0)] ?? $0
        }
        continue
      }

      // values contains the next property label.
      let nextPropertyLabel = values.removeLast()
      properties[label] = values.map {
        return replaced[Substring($0)] ?? $0
      }

      // Insert `nextPropertyLabel` to the beginning of sequence so we can receive property label
      // on next loop.
      sequence.insert(Substring(nextPropertyLabel), at: 0)
    }

    guard !properties.isEmpty else {
      throw CocoaError(.formatting)
    }

    return properties
  }

  func _parse0(_ parseInput: String) throws -> [String: [String]] {
    var replaced: [Substring: String] = [:]

    var newParseInput = ""
    var index = parseInput.startIndex
    var counter = 0

    while index < parseInput.endIndex {
      if parseInput[index] == "\"" {
        // Find the matching closing quote
        let startQuote = index
        index = parseInput.index(after: index)
        var foundClosing = false
        while index < parseInput.endIndex {
          if parseInput[index] == "\"" {
            foundClosing = true
            break
          }
          index = parseInput.index(after: index)
        }
        if foundClosing {
          let quotedRange = parseInput.index(after: startQuote)..<index
          let originalQuoted = parseInput[quotedRange]
          let key = "__TEMP_\(counter)"
          replaced[Substring(key)] = originalQuoted._trimmingWhitespaces()
          newParseInput.append(key)
          counter += 1
          index = parseInput.index(after: index)  // move past closing quote
        } else {
          // No matching closing quote found; append the rest as is and break
          newParseInput.append(contentsOf: parseInput[startQuote...])
          break
        }
      } else {
        newParseInput.append(parseInput[index])
        index = parseInput.index(after: index)
      }
    }

    if index < parseInput.endIndex {
      newParseInput.append(contentsOf: parseInput[index...])
    }

    var properties: [String: [String]] = [:]

    var sequence = newParseInput.split(whereSeparator: { $0 == "=" })

    while !sequence.isEmpty {
      // First element should always represent as property label field.
      let label = sequence.removeFirst()._trimmingWhitespaces()
      guard !label.contains(",") else {
        throw CocoaError(.formatting)
      }

      // If sequence is empty then we can mark it as missing value field.
      guard !sequence.isEmpty else {
        throw CocoaError(.formatting)
      }
      let value = sequence.removeFirst()._trimmingWhitespaces()
      var values = value.split(whereSeparator: { $0 == "," }).map {
        $0._trimmingWhitespaces()
      }

      guard values.count > 1, !sequence.isEmpty else {
        properties[label] = values.map {
          return replaced[Substring($0)] ?? $0
        }
        continue
      }

      // values contains the next property label.
      let nextPropertyLabel = values.removeLast()
      properties[label] = values.map {
        return replaced[Substring($0)] ?? $0
      }

      // Insert `nextPropertyLabel` to the beginning of sequence so we can receive property label
      // on next loop.
      sequence.insert(Substring(nextPropertyLabel), at: 0)
    }

    guard !properties.isEmpty else {
      throw CocoaError(.formatting)
    }

    return properties
  }
}
