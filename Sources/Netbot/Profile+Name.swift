//
// See LICENSE.txt for license information
//

import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension Profile {
  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }
}

#if canImport(SwiftData)
  @available(SwiftStdlib 5.9, *)
  extension Profile.PersistentModel {
    public var name: String {
      url.deletingPathExtension().lastPathComponent
    }
  }
#endif
