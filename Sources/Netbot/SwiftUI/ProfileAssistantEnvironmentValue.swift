//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import SwiftUI

  extension EnvironmentValues {

    @available(SwiftStdlib 5.9, *)
    @Entry public var profileAssistant = ProfileAssistant.shared
  }
#endif
