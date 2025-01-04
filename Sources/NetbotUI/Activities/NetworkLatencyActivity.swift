//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import SwiftUI

  struct NetworkLatencyActivity: View {
    var body: some View {
      HStack {
        GroupBox {
          VStack(alignment: .leading) {
            Label("ROUTER", systemImage: "wifi.router")
              .font(.headline)
              .foregroundColor(Color.cyan)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
              Text("≤1")
                .font(.title)
                .bold()
              Text("ms")
                .bold()
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(minWidth: 150, alignment: .leading)
        }

        GroupBox {
          VStack(alignment: .leading) {
            Label("DNS", systemImage: "safari")
              .font(.headline)
              .foregroundColor(.purple)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
              Text("8")
                .font(.title)
                .bold()
              Text("ms")
                .bold()
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(minWidth: 150, alignment: .leading)
        }

        GroupBox {
          VStack(alignment: .leading) {
            Label {
              Text("INTERNET")
            } icon: {
              Image(systemName: "globe")
                .rotationEffect(Angle(degrees: 90))
            }
            .font(.headline)
            .foregroundColor(.mayaBlue)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
              Text("20")
                .font(.title)
                .bold()
              Text("ms")
                .bold()
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(minWidth: 150, alignment: .leading)
        }
      }
    }
  }

  #if DEBUG
    #Preview {
      NetworkLatencyActivity()
    }
  #endif
#endif
