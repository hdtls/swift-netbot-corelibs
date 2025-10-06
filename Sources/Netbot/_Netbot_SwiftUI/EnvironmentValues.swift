//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import Alamofire
  import SwiftUI

  @available(SwiftStdlib 5.3, *)
  extension EnvironmentValues {

    @Entry public var urlSession = Session.default

    @Entry public var vpnSession = VPNSession.shared

    @available(SwiftStdlib 5.9, *)
    @Entry public var connectivity = Connectivity()

    @available(SwiftStdlib 5.9, *)
    @Entry public var diagnostics = Diagnostics()
  }
#endif
