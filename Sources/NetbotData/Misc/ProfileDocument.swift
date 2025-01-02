//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  public import SwiftUI
  public import UniformTypeIdentifiers

  @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
  extension UTType {

    /// A type that represents Netbot configuration file data.
    ///
    /// **UTI:** com.tenbits.netbot-cfg
    /// **conforms to:** public.text
    static var profile: UTType {
      UTType(exportedAs: "com.tenbits.netbot-cfg", conformingTo: .text)
    }
  }

  @available(iOS 14.0, macOS 11.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public struct ProfileDocument: FileDocument {

    public static var readableContentTypes: [UTType] { [.profile] }

    private var regularFileWithContents = Data()

    public init(contentsOf url: URL?) {
      if let url, let data = try? Data(contentsOf: url) {
        regularFileWithContents = data
      }
    }

    public init(configuration: ReadConfiguration) throws {
      if let data = configuration.file.regularFileContents {
        self.regularFileWithContents = data
      }
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
      .init(regularFileWithContents: regularFileWithContents)
    }
  }
#endif
