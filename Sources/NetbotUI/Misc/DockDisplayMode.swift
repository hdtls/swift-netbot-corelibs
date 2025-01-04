//
// See LICENSE.txt for license information
//

#if EXTENDED_ALL
  import Foundation

  enum DockDisplayMode: Int, CaseIterable, Hashable {
    case always
    case never
    case followTheMainWindow

    var localizedName: String {
      switch self {
      case .always:
        return String(localized: "Always")
      case .never:
        return String(localized: "Never")
      case .followTheMainWindow:
        return String(localized: "Follow the main window")
      }
    }
  }
#endif
