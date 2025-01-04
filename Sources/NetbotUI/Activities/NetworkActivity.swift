//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import SwiftUI

  struct NetworkActivity: View {

    var body: some View {
      Grid {
        GridRow {
          Group {
            VStack(alignment: .leading) {
              Text("Uplaod")
                .textCase(.uppercase)
                .font(.caption)
              HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("0")
                  .font(.title)
                  .bold()
                Text("B/s")
                  .bold()
              }
            }

            VStack(alignment: .leading) {
              Text("Download")
                .textCase(.uppercase)
                .font(.caption)
              HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("0")
                  .font(.title)
                  .bold()
                Text("B/s")
                  .bold()
              }
            }

            VStack(alignment: .leading) {
              Text("Active Connections")
                .textCase(.uppercase)
                .font(.caption)
              Text("10")
                .font(.title)
                .bold()
            }

            VStack(alignment: .leading) {
              Text("Total")
                .textCase(.uppercase)
                .font(.caption)
              HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("2.02")
                  .font(.title)
                  .bold()
                Text("GB")
                  .bold()
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }

  #if DEBUG
    #Preview {
      NetworkActivity()
    }
  #endif
#endif
