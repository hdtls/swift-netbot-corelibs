//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

/// A view of a row in `ProxyStack` or `ProxyGrid`.
struct ProxyCell: View {
  let data: AnyProxy.PersistentModel

  var body: some View {
    VStack(alignment: .leading, spacing: 4.0) {
      #if os(iOS)
        Text(data.name)
          .lineLimit(1)

        HStack {
          Text(data.kind.localizedName)
            .font(.footnote)
            .foregroundColor(Color.white)
            .padding(.horizontal, 4.0)
            .background(Color.blue)
            .cornerRadius(3.0)

          if data.kind.isProxyable {
            Text(data.serverAddress)
              .font(.footnote)
          }
        }
      #else
        Text(data.kind.localizedName)
          .font(.footnote)
          .foregroundColor(.secondary)

        Text(data.name)
          .lineLimit(1)

        Spacer()
        Text("Failed")
          .font(.caption)
          .foregroundColor(textColor)
      #endif
    }
  }

  private var textColor: Color {
    .red
  }
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable<AnyProxy.PersistentModel> {
      ProxyCell(data: $0.first.unsafelyUnwrapped)
        #if os(macOS)
          .frame(width: 150, height: 80, alignment: .leading)
        #endif
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [AnyProxy.PersistentModel]
    ProxyCell(data: models.first.unsafelyUnwrapped)
      #if os(macOS)
        .frame(width: 150, height: 80, alignment: .leading)
      #endif
  }
#endif
