//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
public import SwiftUI

public struct ContentView: View {
  #if EXTENDED_ALL
    @State private var page: Pages = .activity
  #else
    @State private var page: Pages = .policy
  #endif

  public init() {}

  public var body: some View {
    NavigationSplitView {
      Sidebar(selection: $page)
        .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 250)
    } detail: {
      page.body
    }
  }
}
