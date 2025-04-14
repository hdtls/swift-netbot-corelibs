//
// See LICENSE.txt for license information
//

import _ResourceProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

extension Profile {
  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }
}

#if canImport(SwiftData)
  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension Profile.PersistentModel {
    public var name: String {
      url.deletingPathExtension().lastPathComponent
    }
  }
#endif
