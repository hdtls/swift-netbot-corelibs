//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct PropertiesParseStrategy {

  func parse(_ parseInput: String) throws -> [String: [String]] {
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
}
