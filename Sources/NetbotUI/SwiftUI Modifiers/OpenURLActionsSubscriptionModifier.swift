//
// See LICENSE.txt for license information
//

import SwiftUI

struct OpenURLActionsSubscriptionModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.environment(
      \.openURL,
      OpenURLAction { url in
        #if os(macOS)
          guard url.isFileURL else {
            return .systemAction
          }
          NSWorkspace.shared.activateFileViewerSelecting([url])
          return .handled
        #else
          return .systemAction
        #endif
      })
  }
}

extension View {
  func subscribeOpenURLActions() -> some View {
    modifier(OpenURLActionsSubscriptionModifier())
  }
}
