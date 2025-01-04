//
// See LICENSE.txt for license information
//

import SwiftUI

struct DownloadProgress: View {
  @Binding var urls: [URL]?

  var body: some View {
    if let urls {
      VStack(alignment: .leading) {
        ForEach(urls, id: \.self) {
          Row(data: $urls, url: $0)
        }
      }
      .padding()
    }
  }
}

extension DownloadProgress {
  private struct Row: View {
    @State private var lastError: (any Error)?
    @State private var presentingErrorSheet = false
    @Binding var data: [URL]?
    let url: URL
    private let engine = Engine()
    private var suggestedFilename: String {
      url.deletingPathExtension().lastPathComponent
    }
    private let font = Font.system(size: 13)

    var body: some View {
      HStack {
        Image(.configFile)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 40)
          .padding(4)
          .overlay(alignment: .bottomTrailing) {
            if lastError != nil {
              Image(systemName: "xmark")
                .symbolVariant(.circle.fill)
                .foregroundStyle(.red)
                .font(font)
            }
          }

        VStack(alignment: .leading) {
          Text(suggestedFilename)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
          if lastError != nil {
            Text("Failed - Could not download \(suggestedFilename)")
              .foregroundStyle(.secondary)
              .font(.footnote)
          } else {
            ProgressView(engine.progress)
          }
        }

        if let lastError {
          Button {
            presentingErrorSheet = true
          } label: {
            Image(systemName: "info")
              .symbolVariant(.circle.fill)
              .foregroundStyle(.secondary)
              .font(font)
          }
          .buttonStyle(.plain)
          .sheet(isPresented: $presentingErrorSheet) {
            DownloadProgress.ErrorDetailsSheet(filename: suggestedFilename, error: lastError)
          }
        }

        Button {
          if lastError != nil {
            Task {
              await startDownloading()
            }
          } else {
            engine.cancel()
          }
        } label: {
          Group {
            if lastError != nil {
              Image(systemName: "arrow.counterclockwise")
                .foregroundStyle(Color.orange)
            } else {
              Image(systemName: "xmark")
                .foregroundStyle(.secondary)
            }
          }
          .symbolVariant(.circle.fill)
          .font(font)
        }
        .buttonStyle(.plain)
      }
      .task {
        await startDownloading()
      }
    }

    private func startDownloading() async {
      do {
        lastError = nil
        try await engine.download(url)
        data?.removeAll(where: { $0 == url })
      } catch {
        lastError = error
      }
    }
  }
}

#if DEBUG
  #Preview {
    DownloadProgress(
      urls: .constant([
        URL(string: "https://abc/tvOS 17.4 Simulator (21L224)")!,
        URL(string: "https://abc/tvOS 17.4 Simulator (21L224)")!,
      ])
    )
    .frame(width: 400)
    .fixedSize()
  }
#endif
