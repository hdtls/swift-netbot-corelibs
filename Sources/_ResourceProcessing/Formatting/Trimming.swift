//
// See LICENSE.txt for license information
//

#if !canImport(FoundationEssentials)
  private import Foundation
#else

  // swift-format-ignore: AlwaysUseLowerCamelCase
  let NSDebugDescriptionErrorKey = "NSDebugDescriptionErrorKey"

  extension BidirectionalCollection {
    func _trimmingCharacters(while predicate: (Element) -> Bool) -> SubSequence {
      var idx = startIndex
      while idx < endIndex && predicate(self[idx]) {
        formIndex(after: &idx)
      }

      let startOfNonTrimmedRange = idx  // Points at the first char not in the set
      guard startOfNonTrimmedRange != endIndex else {
        return self[endIndex...]
      }

      let beforeEnd = index(before: endIndex)
      guard startOfNonTrimmedRange < beforeEnd else {
        return self[startOfNonTrimmedRange..<endIndex]
      }

      var backIdx = beforeEnd
      // No need to bound-check because we've already trimmed from the beginning, so we'd definitely break off of this loop before `backIdx` rewinds before `startIndex`
      while predicate(self[backIdx]) {
        formIndex(before: &backIdx)
      }
      return self[startOfNonTrimmedRange...backIdx]
    }
  }
#endif

extension String {

  func _trimmingWhitespaces() -> String {
    #if canImport(FoundationEssentials)
      if self.isEmpty {
        return ""
      }

      return String(
        unicodeScalars._trimmingCharacters {
          $0.properties.isWhitespace
        })
    #else
      trimmingCharacters(in: .whitespaces)
    #endif
  }
}

extension Substring {

  func _trimmingWhitespaces() -> String {
    #if canImport(FoundationEssentials)
      if self.isEmpty {
        return ""
      }

      return String(
        unicodeScalars._trimmingCharacters {
          $0.properties.isWhitespace
        })
    #else
      trimmingCharacters(in: .whitespaces)
    #endif
  }
}
