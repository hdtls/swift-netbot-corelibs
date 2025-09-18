//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import SwiftUI

  @available(SwiftStdlib 5.9, *)
  extension EnvironmentValues {

    @Entry public var recentConnections = RecentConnectionsStore.shared
  }
#endif
