//
// See LICENSE.txt for license information
//

import AnlzrReports

@available(SwiftStdlib 5.3, *)
extension Connection.State {

  public var localizedName: String {
    switch self {
    case .establishing:
      return "Establishing"
    case .active:
      return "Active"
    case .completed:
      return "Completed"
    case .failed:
      return "Failed"
    case .cancelled:
      return "Cancelled"
    }
  }
}
