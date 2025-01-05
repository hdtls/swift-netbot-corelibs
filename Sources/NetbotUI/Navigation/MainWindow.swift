//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import SwiftUI

  class MainWindow: NSWindow {

    convenience init() {
      self.init(
        contentRect: .zero,
        styleMask: [.titled, .fullSizeContentView, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: true
      )

      contentView = NSHostingView(
        rootView: ContentView()
          .subscribeOpenURLActions()
          .frame(minWidth: 900, minHeight: 510)
          .modelContainer(ProfileAssistant.shared.modelContainer)
      )

      titleVisibility = .hidden
      titlebarAppearsTransparent = true
      isReleasedWhenClosed = false
    }
  }
#endif
