//
// See LICENSE.txt for license information
//

import SwiftUI

extension DownloadProgress {
  struct ErrorDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var errorDetailsIsVisible = false
    let filename: String
    let error: any Error

    var body: some View {
      NavigationStack {
        VStack(alignment: .leading) {
          HStack {
            Group {
              #if os(iOS)
                Image(uiImage: UIImage(named: "AppIcon")!)
                  .resizable()
              #else
                Image(nsImage: NSImage(named: "AppIcon")!)
                  .resizable()
              #endif
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 56)
            .padding(.trailing, 8)

            VStack(alignment: .leading) {
              Text("Could not download \(filename).")
                .font(.headline)
              Text("\(error.localizedDescription)")
                .font(.footnote)
                .padding(.vertical, 1)
            }
          }
          if errorDetailsIsVisible {
            TextEditor(text: .constant(error.localizedDescription))
              .frame(minHeight: 100, maxHeight: 160)
              .border(.gray.opacity(0.3), width: 1)
          }
        }
        .padding()
        .frame(width: 455, alignment: .leading)
        .toolbar {
          ToolbarItem {
            Button(errorDetailsIsVisible ? "hide Details" : "Show Details") {
              errorDetailsIsVisible.toggle()
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("OK") {
              dismiss()
            }
          }
        }
      }
    }
  }
}

#if DEBUG
  #Preview {
    DownloadProgress.ErrorDetailsSheet(
      filename: "", error: URLError(.badURL)
    )
    .frame(height: 300)
  }
#endif
