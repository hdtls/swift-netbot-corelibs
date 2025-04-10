//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import AnlzrReports
  import Dashboard
  import SwiftUI

  struct ConnectionState: View, Equatable {

    private var data: Connection.State

    init(_ data: Connection.State) {
      self.data = data
    }

    var body: some View {
      switch data {
      case .establishing, .active:
        Image(systemName: "arrow.left.and.right")
          .symbolVariant(.circle.fill)
          .symbolRenderingMode(.palette)
          .foregroundStyle(Color.white, Color.green)
      case .completed:
        Image(systemName: "checkmark")
          .symbolVariant(.circle.fill)
          .symbolRenderingMode(.palette)
          .foregroundStyle(Color.white, Color.blue)
      case .failed, .cancelled:
        Image(systemName: "xmark")
          .symbolVariant(.circle.fill)
          .symbolRenderingMode(.palette)
          .foregroundStyle(Color.white, Color.red)
      }
    }
  }

  #Preview {
    List {
      ConnectionState(.establishing)
      ConnectionState(.active)
      ConnectionState(.completed)
      ConnectionState(.cancelled)
      ConnectionState(.failed)
    }
  }
#endif
