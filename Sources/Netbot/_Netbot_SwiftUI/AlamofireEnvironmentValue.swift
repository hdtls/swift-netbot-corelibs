//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import SwiftUI

  @available(SwiftStdlib 5.3, *)
  extension EnvironmentValues {

    @Entry public var urlSession = URLSession.shared
  }
#endif
