//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import SwiftUI

  extension EnvironmentValues {

    @available(swift 5.9)
    @available(SwiftStdlib 5.9, *)
    @Entry public var connectivity = Connectivity()
  }
#endif
