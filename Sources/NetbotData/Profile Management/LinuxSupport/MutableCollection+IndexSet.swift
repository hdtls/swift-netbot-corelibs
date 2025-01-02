//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import struct Foundation.IndexSet

  #if !canImport(SwiftUI)
    extension RangeReplaceableCollection where Self: MutableCollection {

      /// Removes all the elements at the specified offsets from the collection.
      ///
      mutating func remove(atOffsets offsets: IndexSet) {
        //        var finalize: Self = .init()
        //
        //        for (index, element) in self.enumerated() {
        //          if offsets.contains(index) {
        //            continue
        //          }
        //          finalize.append(element)
        //        }
        //
        //        self = finalize
        let subranges = RangeSet(
          offsets.map {
            let lowerBound = index(startIndex, offsetBy: $0)
            return lowerBound..<index(lowerBound, offsetBy: 1)
          })
        removeSubranges(subranges)
      }
    }

    extension MutableCollection {
      mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let subranges = RangeSet(
          source.map {
            let lowerBound = index(startIndex, offsetBy: $0)
            return lowerBound..<index(lowerBound, offsetBy: 1)
          })
        moveSubranges(subranges, to: index(startIndex, offsetBy: destination))
      }
    }
  #endif
#endif
