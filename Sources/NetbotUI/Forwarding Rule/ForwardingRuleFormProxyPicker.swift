//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

extension ForwardingRuleForm {

  struct ProxyPicker: View {
    @Binding private var selection: String
    @Query(sort: \AnyProxy.PersistentModel.creationDate)
    private var lazyProxies: [AnyProxy.PersistentModel]

    @Query(sort: \AnyProxyGroup.PersistentModel.creationDate)
    private var lazyProxyGroups: [AnyProxyGroup.PersistentModel]

    private let titleKey: LocalizedStringKey

    init(_ titleKey: LocalizedStringKey, selection: Binding<String>) {
      self.titleKey = titleKey
      self._selection = selection
    }

    var body: some View {
      Picker(titleKey, selection: $selection) {
        let proxies = lazyProxies.filter { $0.kind.isProxyable }
        let others = lazyProxies.filter { !$0.kind.isProxyable }

        if !others.isEmpty {
          Section {
            ForEach(others, id: \.name) {
              Text($0.name)
            }
          }
        }

        if !proxies.isEmpty {
          Section {
            ForEach(proxies, id: \.name) {
              Text($0.name)
            }
          }
        }

        if !lazyProxyGroups.isEmpty {
          Section {
            ForEach(lazyProxyGroups, id: \.name) {
              Text($0.name)
            }
          }
        }
      }
      .accessibilityIdentifier("Rule - Proxy PopUpButton")
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @State var selection = "DIRECT"
    ForwardingRuleForm.ProxyPicker("Proxy", selection: $selection)
  }
#endif
