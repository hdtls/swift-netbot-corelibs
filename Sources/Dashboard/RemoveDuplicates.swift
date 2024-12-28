//
// See LICENSE.txt for license information
//

extension Sequence where Element: Hashable {

  /// Return the sequence with all duplicates removed.
  ///
  /// i.e. `[ 1, 2, 3, 1, 2 ].removeDuplicates() == [ 1, 2, 3 ]`
  public func removeDuplicates() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}
