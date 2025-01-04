//
// See LICENSE.txt for license information
//

import SwiftUI

struct AlamofireEnvironmentKey: EnvironmentKey {
  static let defaultValue = URLSession.shared
}

extension EnvironmentValues {
  var session: URLSession {
    get { self[AlamofireEnvironmentKey.self] }
    set { fatalError("Use default session directly.") }
  }
}
