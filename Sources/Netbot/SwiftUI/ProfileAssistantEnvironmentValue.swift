//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import SwiftUI

  extension EnvironmentValues {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Entry public var profileAssistant = ProfileAssistant.shared
  }
#endif
