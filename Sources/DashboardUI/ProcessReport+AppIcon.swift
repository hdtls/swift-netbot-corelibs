//
// See LICENSE.txt for license information
//

#if os(macOS)
  import AnlzrReports
  import AppKit
  import SwiftUI
  import UniformTypeIdentifiers

  extension ProcessReport {

    private var processImage: NSImage {
      if let data = processIconTIFFRepresentation, let image = NSImage(data: data) {
        return image
      }

      if let url = processBundleURL {
        if #available(macOS 13.0, *) {
          return NSWorkspace.shared.icon(forFile: url.path())
        } else {
          // Fallback on earlier versions
          return NSWorkspace.shared.icon(forFile: url.path)
        }
      }

      if processExecutableURL != nil {
        if #available(macOS 11.0, *) {
          return NSWorkspace.shared.icon(for: .unixExecutable)
        } else {
          return NSWorkspace.shared.icon(forFileType: "public.unix-executable")
        }
      }

      return NSImage()
    }

    public var processIcon: some View {
      Image(nsImage: processImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }
#endif
