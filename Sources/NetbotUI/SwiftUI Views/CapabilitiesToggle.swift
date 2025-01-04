//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

/// A control that toggles between on and off states of specified capability flag.
struct CapabilitiesToggle<Label>: View where Label: View {
  @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
  private var enabledHTTPCapabilities: CapabilityFlags = []

  let option: CapabilityFlags
  @ViewBuilder let label: () -> Label

  private var isOn: Binding<Bool> {
    .init {
      enabledHTTPCapabilities.contains(option)
    } set: {
      if $0 {
        enabledHTTPCapabilities.insert(option)
      } else {
        enabledHTTPCapabilities.remove(option)
      }
    }
  }

  var body: some View {
    Toggle(isOn: isOn, label: label)
  }
}
