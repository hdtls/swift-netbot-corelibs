//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct DNSOptionsSettings: View {
  #if os(macOS)
    @AppStorage(Prefs.Name.shouldReadLocalDNSRecords) private var shouldReadLocalDNSRecords = false
  #endif
  @AppStorage(Prefs.Name.shouldEnableLocalDNSMapping) private var shouldEnableLocalDNSMapping =
    false

  var body: some View {
    Section {
      #if os(macOS)
        Toggle("Read local DNS records from /etc/hosts", isOn: $shouldReadLocalDNSRecords)
      #endif
      Toggle(
        "Use local DNS mapping result for requests via proxy",
        isOn: $shouldEnableLocalDNSMapping
      )
    } header: {
      Text("Options")
    } footer: {
      Group {
        Text(
          "By default, the DNS resolve always happens on the remote proxy server since \(ProcessInfo.processInfo.processName) always sends proxy requests with domains."
        )
        Text(
          "After enabling this option, for the requests that matched a local DNS mapping record, \(ProcessInfo.processInfo.processName) sends proxy requests with IP addresses instead of the original domains."
        )
        Text("It only works for local DNS mapping records with an IP address.")
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
      #if os(macOS)
        .frame(width: 430, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
      #endif
    }
  }
}

#if DEBUG
  #Preview {
    Form {
      DNSOptionsSettings()
    }
  }
#endif
