//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import struct Foundation.URLResourceKey
#else
  import Foundation
#endif

#if !canImport(FoundationEssentials)
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  extension ParseableFormatStyle where Self == URL.FormatStyle {

    public static var _url: URL.FormatStyle {
      .init(path: .omitWhen(.path, matches: ["/"]), query: .omitWhen(.query, matches: [""]))
    }
  }
#endif

extension URL {
  public var isDirectory: Bool {
    (try? self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
  }

  public var contentModificationDate: Date? {
    try? self.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
  }

  public var suggestedFilename: String {
    deletingPathExtension().lastPathComponent
  }
}
