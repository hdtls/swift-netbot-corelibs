//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

/// A view of a cell in `ProxyGroupStack` or `ProxyGroupGrid`.
struct ProxyGroupCell: View {
  @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
  private var selectionRecordForGroups = SelectionRecordForGroups()
  let data: AnyProxyGroup.PersistentModel

  #if os(iOS)
    var body: some View {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(data.name)
            .lineLimit(1)

          Text(data.kind.localizedName)
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        Spacer()
        if let selectedPolicyName {
          Text(selectedPolicyName)
        }
      }
    }
  #else
    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(data.kind.localizedName)
          .font(.footnote)
          .foregroundColor(.secondary)

        Text(data.name)
          .lineLimit(1)

        Spacer()
        if let selectedPolicyName {
          Text(selectedPolicyName)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
  #endif

  private var selectedPolicyName: String? {
    selectionRecordForGroups[data.name]
  }
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable<AnyProxyGroup.PersistentModel> {
      ProxyGroupCell(data: $0.first.unsafelyUnwrapped)
        #if os(macOS)
          .frame(width: 150, height: 80, alignment: .leading)
        #endif
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [AnyProxyGroup.PersistentModel]
    ProxyGroupCell(data: models.first.unsafelyUnwrapped)
      #if os(macOS)
        .frame(width: 150, height: 80, alignment: .leading)
      #endif
  }
#endif
