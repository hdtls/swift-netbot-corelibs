//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

extension ProfileSettings {
  struct Alert {
    enum Kind {
      case create
      case rename
      case delete
    }

    var title: LocalizedStringKey {
      switch kind {
      case .create:
        return "New Empty Profile"
      case .rename:
        return "Rename Profile"
      case .delete:
        return "Delete Profile"
      }
    }

    @ViewBuilder func message(_ presenting: URL) -> some View {
      if case .delete = kind {
        Text(
          "Are you sure you want to permanently delete the profile \"\(presenting.suggestedFilename)\""
        )
      }
    }

    var kind: Kind
    var isPresented: Bool = true
  }
}
