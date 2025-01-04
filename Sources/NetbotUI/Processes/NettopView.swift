//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  public import SwiftUI

  public struct NettopView: View {
    private let data: [ProcessStatistics]

    public init(data: [ProcessStatistics]) {
      self.data = data
    }

    public var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        if data.isEmpty {
          HStack {
            Text(verbatim: "-")
              .foregroundColor(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
            Spacer()
          }
        } else {
          ForEach(data) { process in
            ProcessCell(process: process)
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }
#endif

extension Double {

  func formattedSpeedString() -> String {
    switch self {
    case 1024..<(1024 * 1024):
      return "\(String(format: "%.0f", self / 1024)) KB/s"
    case 1024..<(1024 * 1024 * 1024):
      let megabytes = self / 1024 / 1024
      return "\(String(format: "%.\(megabytes >= 100 ? 0 : 1)f", megabytes)) MB/s"
    case (1024 * 1024 * 1024)...:
      let gigabytes = self / 1024 / 1024 / 1024
      return "\(String(format: "%.\(gigabytes >= 100 ? 0 : 1)f", gigabytes)) GB/s"
    default:
      return "\(Int(self)) B/s"
    }
  }
}
