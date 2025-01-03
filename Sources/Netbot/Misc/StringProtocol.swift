//
// See LICENSE.txt for license information
//

extension StringProtocol {
  func trimmingWhitespaces() -> String {
    self.trimmingCharacters(in: .whitespaces)
  }
}
