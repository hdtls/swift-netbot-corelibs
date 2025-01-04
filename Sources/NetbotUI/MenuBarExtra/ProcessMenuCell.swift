//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import SwiftUI

  struct ProcessMenuCell: View {
    let processInfo: ProcessStatistics

    var body: some View {
      HStack {
        Label {
          Text(processInfo.localizedName)
        } icon: {
          Image(nsImage: processInfo.icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
      }
    }
  }
#endif
