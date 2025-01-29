//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct HTTPRewritesPage: View {

  var body: some View {
    VStack(alignment: .leading) {
      CapabilitiesToggle(option: .rewrite) {
        Text("Rewrite & Mapping")
          .font(.largeTitle)
          .bold()
      }
      .toggleStyle(.switch)

      Text("Redirect HTTP requests or modify request headers.")
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.bottom)

      URLRewriteGallery()

      StubbedHTTPResponseGallery()

      HTTPFieldsRewriteGallery()
    }
    .padding()
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    HTTPRewritesPage()
  }
#endif
