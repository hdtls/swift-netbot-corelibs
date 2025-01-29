//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import SwiftData
  import SwiftUI

  struct ProxyGroupEditor: View {
    @Binding var data: AnyProxyGroup
    @Binding var step: ProxyGroupEditingSheet.EditingStep

    var body: some View {
      Group {
        switch step {
        case .selectType:
          ProxyGroupEditorKindGroup(data: $data)
        case .selectPolicies:
          ProxyGroupEditorINCLProxiesGroup(data: $data)
        case .editName:
          if case .urlTest = data.kind {
            ProxyGroupEditorAutoURLTestNameGroup(data: $data)
          } else {
            Form {
              TextField("Group Name", text: $data.name)
            }
            .padding(.horizontal)
          }
        }
      }
    }
  }

  #if DEBUG
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview(traits: .persistentStore()) {
      @Previewable @State var data = AnyProxyGroup()
      @Previewable @State var step = ProxyGroupEditingSheet.EditingStep.selectType
      ProxyGroupEditor(data: $data, step: $step)
    }
  #endif
#endif
