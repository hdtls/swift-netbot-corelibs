//
// See LICENSE.txt for license information
//

import SwiftUI

struct ListRow: View {
  let text: String
  let detailText: String

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(text)
        Text(detailText)
          .font(.footnote)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    .contentShape(Rectangle())
  }
}
