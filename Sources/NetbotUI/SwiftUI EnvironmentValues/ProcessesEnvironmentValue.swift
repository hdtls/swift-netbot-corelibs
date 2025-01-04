//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import SwiftUI

  struct ProcessesEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = ProcessesStore()
  }

  extension EnvironmentValues {
    var processes: ProcessesStore {
      get { self[ProcessesEnvironmentKey.self] }
      set { self[ProcessesEnvironmentKey.self] = newValue }
    }
  }
#endif
