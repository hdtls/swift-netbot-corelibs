//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import SwiftData
  import SwiftUI

  struct ProxyGroupEditorINCLProxiesGroup: View {
    typealias Data = AnyProxy.PersistentModel

    @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
    private var selectionRecordForGroups = SelectionRecordForGroups()
    @Binding private var data: AnyProxyGroup
    @Query(sort: \Data.creationDate) private var searchResults: [Data]

    init(data: Binding<AnyProxyGroup>) {
      self._data = data
    }

    var body: some View {
      switch data.kind {
      case .ssid:
        List {}
      default:
        VStack(alignment: .leading, spacing: 8) {
          Picker(selection: $data.resource.source) {
            ForEach(AnyProxyGroup.Resource.Source.allCases, id: \.self) {
              Text($0.horizontalRadioGroupItemTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .pickerStyle(.radioGroup)
          .horizontalRadioGroupLayout()
          .frame(maxWidth: .infinity)

          HStack(alignment: .top) {
            Table(searchResults) {
              TableColumn("") { proxy in
                Toggle(
                  "",
                  isOn: .init(get: { exists(proxy) }, set: { _ in markPolicyStatus(proxy) })
                )
                .labelsHidden()
                .toggleStyle(.checkbox)
              }
              .width(20)
              TableColumn("Policy") { proxy in
                Text(proxy.name)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .contentShape(Rectangle())
                  .onTapGesture {
                    markPolicyStatus(proxy)
                  }
              }
            }

            Divider()

            VStack(alignment: .leading) {
              Text(
                "Use a proxy list from the proxy provider. The list should be a text file. Each line of file contains a proxy declaration."
              )
              .foregroundColor(.secondary)
              TextField(
                "URL or Local File Path", value: $data.resource.externalProxiesURL, format: ._url)
              HStack {
                Text("Auto-update interval:")
                  .layoutPriority(1)
                TextField(
                  "", value: $data.resource.externalProxiesAutoUpdateTimeInterval, format: .number
                )
                .onChange(of: data.resource.externalProxiesAutoUpdateTimeInterval) {
                  // TODO: SCHEDULE AUTO UPDATE FOR EXTERNAL POLICIES
                }
                Text("seconds")
              }
            }
          }
        }
        .frame(minHeight: 250)
      }
    }

    private func exists(_ proxy: Data) -> Bool {
      return data.lazyProxies.contains(proxy.name)
    }

    private func markPolicyStatus(_ proxy: Data) {
      if exists(proxy) {
        data.lazyProxies.removeAll(where: { $0 == proxy.name })
      } else {
        data.lazyProxies.append(proxy.name)
      }
    }
  }

  extension AnyProxyGroup.Resource.Source {
    fileprivate var horizontalRadioGroupItemTitle: LocalizedStringKey {
      switch self {
      case .cache:
        return "Select Policy"
      case .query:
        return "Use External Proxy List"
      }
    }
  }

  #if DEBUG
    #Preview {
      PersistentStorePreviewable {
        BindingPreviewable(AnyProxyGroup()) { $data in
          ProxyGroupEditorINCLProxiesGroup(data: $data)
        }
      }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview(traits: .persistentStore()) {
      @Previewable @State var data = AnyProxyGroup()
      ProxyGroupEditorINCLProxiesGroup(data: $data)
    }
  #endif
#endif
