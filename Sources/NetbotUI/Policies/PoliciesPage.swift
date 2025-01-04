//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct PoliciesPage: View {

  @AppStorage(Prefs.Name.outboundMode, store: .applicationGroup) var outboundMode = OutboundMode
    .direct

  private let spacing: CGFloat = 16
  private var columns: [GridItem] {
    [
      GridItem(.adaptive(minimum: 150, maximum: 150), spacing: spacing, alignment: .leading)
    ]
  }

  #if os(iOS)
    var body: some View {
      List {
        ProxyGrid()
        ProxyGroupStack()
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Policy")
    }
  #else
    var body: some View {
      VStack(alignment: .leading) {
        Text("Policy")
          .font(.largeTitle)
          .bold()
          .padding(.bottom)

        Picker(selection: $outboundMode) {
          ForEach(OutboundMode.allCases, id: \.self) { mode in
            Text(mode.localizedName)
              .help("Change Outbound Mode to \(mode.localizedName)")
          }
        }
        .pickerStyle(.segmented)
        .fixedSize()

        Text(outboundMode.localizedDescription)
          .accessibilityIdentifier("Policies - Current Outbound Mode Summary Label")
          .font(.footnote)
          .foregroundColor(.secondary)
          .padding(.bottom)

        ScrollView {
          LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ProxyGrid()
            ProxyGroupGrid()
          }
        }
      }
      .padding()
      .navigationTitle("Policy")
    }
  #endif
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable {
      PoliciesPage()
        #if os(macOS)
          .frame(width: 650, height: 510)
        #endif
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    PoliciesPage()
      #if os(macOS)
        .frame(width: 650, height: 510)
      #endif
  }
#endif
