//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  @_exported public import struct Foundation.IndexSet

  #if !canImport(SwiftUI)
    extension RangeReplaceableCollection where Self: MutableCollection {

      /// Removes all the elements at the specified offsets from the collection.
      ///
      /// - Complexity: O(*n*) where *n* is the length of the collection.
      ///
      public mutating func remove(atOffsets offsets: IndexSet) {

      }
    }

    extension MutableCollection {

      public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {

      }
    }
  #endif
#endif
