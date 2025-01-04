//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import SwiftUI

  struct ProxyGroupEditorKindGroup: View {
    @Binding var data: AnyProxyGroup

    var body: some View {
      Picker(selection: $data.kind) {
        ForEach(AnyProxyGroup.Kind.allCases, id: \.self) { kind in
          VStack(alignment: .leading) {
            Text(kind.localizedName)
            Text(kind.localizedDescription)
              .font(.footnote)
              .foregroundColor(.secondary)
              .padding(.bottom, kind == AnyProxyGroup.Kind.allCases.last ? 0 : nil)
          }
        }
      }
      .pickerStyle(.radioGroup)
      .fixedSize(horizontal: true, vertical: false)
    }
  }

  #if DEBUG
    #Preview {
      BindingPreviewable(AnyProxyGroup()) { $data in
        ProxyGroupEditorKindGroup(data: $data)
      }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview {
      @Previewable @State var data = AnyProxyGroup()
      ProxyGroupEditorKindGroup(data: $data)
    }
  #endif
#endif
