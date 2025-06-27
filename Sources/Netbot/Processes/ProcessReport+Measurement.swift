//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation
  import SwiftData

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  public struct ProcessReport: Hashable, Identifiable, Sendable {

    public var id: String { processName }

    /// Indicates the name of the application.
    /// This is dependent on the current localization of the referenced app, and is suitable for presentation to the user.
    public var processName: String

    /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
    public var processBundleURL: URL?

    /// Indicates the URL to the application's executable.
    public var processExecutableURL: URL?

    /// Indicates the process identifier (pid) of the application.
    public var processIdentifier: Int32?

    /// Indicates the icon TIFF representation data of the application.
    public var processIconTIFFRepresentation: Data?

    public var countOfReceivedBytes: Int64

    public var countOfSentBytes: Int64

    public var countOfReceivedBytesPerSecond: Int64

    public var countOfSentBytesPerSecond: Int64
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension ProcessReport {

    public enum CompareOptions: CaseIterable, Hashable, Sendable {

      case traffic
      case speed
      case name

      var sortDescriptor: SortDescriptor<ProcessReport> {
        switch self {
        case .traffic:
          return SortDescriptor(\.countOfReceivedBytes, order: .reverse)
        case .speed:
          return SortDescriptor(\.countOfReceivedBytesPerSecond, order: .reverse)
        case .name:
          return SortDescriptor(\.processName)
        }
      }

      public var localizedName: String {
        switch self {
        case .traffic:
          return String(localized: "Sort by Traffic")
        case .speed:
          return String(localized: "Sort by Speed")
        case .name:
          return String(localized: "Sort by Name")
        }
      }
    }
  }
#endif
