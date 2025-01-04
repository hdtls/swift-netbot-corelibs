//
// See LICENSE.txt for license information
//

import SwiftUI

#if os(macOS)
  enum _EditMode {

    /// The user can't edit the view content.
    ///
    /// The ``isEditing`` property is `false` in this state.
    case inactive

    /// The view is in a temporary edit mode.
    ///
    /// The use of this state varies by platform and for different
    /// controls. As an example, SwiftUI might engage temporary edit mode
    /// over the duration of a swipe gesture.
    ///
    /// The ``isEditing`` property is `true` in this state.
    case transient

    /// The user can edit the view content.
    ///
    /// The ``isEditing`` property is `true` in this state.
    case active

    /// Indicates whether a view is being edited.
    ///
    /// This property returns `true` if the mode is something other than
    /// inactive.
    var isEditing: Bool {
      switch self {
      case .inactive:
        return false
      case .transient:
        return true
      case .active:
        return true
      }
    }
  }
  typealias EditMode = _EditMode
#endif
