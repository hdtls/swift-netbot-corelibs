//
// See LICENSE.txt for license information
//

import _ProfileSupport

extension Array where Element == Substring {

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  func firstRange(match sectionRegex: some RegexComponent) -> ClosedRange<Int>? {
    guard var start = firstIndex(where: { !$0.matches(of: sectionRegex).isEmpty }) else {
      return nil
    }

    guard start < endIndex else {
      return start...endIndex
    }

    start = index(after: start)
    let slice = suffix(from: start)
    var end = endIndex

    if let endIndex = slice.firstIndex(where: { !$0.matches(of: /^ *\[.+] *$/).isEmpty }) {
      end = endIndex
    }

    // Trimming empty lines.
    while end - 1 >= start {
      guard self[end - 1]._trimmingWhitespaces().isEmpty else {
        break
      }
      end = end - 1
    }

    return start...end
  }
}
