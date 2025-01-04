//
// See LICENSE.txt for license information
//

#if EXTENDED_ALL
  import SwiftUI

  struct PrivateDNSSettings: View {
    var body: some View {
      Section("DDNS") {
        Button("Configure \(ProcessInfo.processInfo.processName) private DDNS...") {}
      }
    }
  }
#endif
