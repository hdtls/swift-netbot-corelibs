//
// See LICENSE.txt for license information
//

#if os(macOS)
  import AnlzrReports
  import Foundation
  import SwiftData

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  public struct ProcessReport: Hashable, Identifiable, Sendable {

    @MainActor @Observable final public class Metrics {

      public var totalBytesReceived = Measurement<UnitInformationStorage>(value: 0, unit: .bytes)

      public var formattedCountOfBytesReceived: String {
        totalBytesReceived.formatted(.byteCount(style: .binary))
      }

      public var totalBytesSent = Measurement<UnitInformationStorage>(value: 0, unit: .bytes)

      public var formattedCountOfBytesSent: String {
        totalBytesSent.formatted(.byteCount(style: .binary))
      }

      public var bytesReceived = Measurement<UnitInformationStorage>(
        value: 0, unit: .bytes)

      public var formattedDownloadSpeed: String {
        "\(bytesReceived.formatted(.byteCount(style: .binary)))/s"
      }

      public var bytesSent = Measurement<UnitInformationStorage>(
        value: 0, unit: .bytes)

      public var formattedUploadSpeed: String {
        "\(bytesSent.formatted(.byteCount(style: .binary)))/s"
      }

      public var countOfActiveConnections = 0

      public var connections: [Connection.ID] = []

      public var processIdentifiers: [Int32] = []

      public init(
        totalBytesReceived: Measurement<UnitInformationStorage> = .init(value: 0, unit: .bytes),
        totalBytesSent: Measurement<UnitInformationStorage> = .init(value: 0, unit: .bytes),
        bytesReceived: Measurement<UnitInformationStorage> = .init(value: 0, unit: .bytes),
        bytesSent: Measurement<UnitInformationStorage> = .init(value: 0, unit: .bytes),
        countOfActiveConnections: Int = 0,
        connections: [Connection.ID] = [],
        processIdentifiers: [Int32] = []
      ) {
        self.totalBytesReceived = totalBytesReceived
        self.totalBytesSent = totalBytesSent
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.countOfActiveConnections = countOfActiveConnections
        self.connections = connections
        self.processIdentifiers = processIdentifiers
      }
    }

    public var id: String { processName }

    /// Indicates the name of the application.
    /// This is dependent on the current localization of the referenced app, and is suitable for presentation to the user.
    public var processName: String

    /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
    public var processBundleURL: URL?

    /// Indicates the URL to the application's executable.
    public var processExecutableURL: URL?

    /// Indicates the icon TIFF representation data of the application.
    public var processIconTIFFRepresentation: Data?

    public let transactionMetrics: Metrics

    public static func == (lhs: ProcessReport, rhs: ProcessReport) -> Bool {
      lhs.processName == rhs.processName
        && lhs.processBundleURL == rhs.processBundleURL
        && lhs.processExecutableURL == rhs.processExecutableURL
        && lhs.processIconTIFFRepresentation == rhs.processIconTIFFRepresentation
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(processName)
      hasher.combine(processBundleURL)
      hasher.combine(processExecutableURL)
      hasher.combine(processIconTIFFRepresentation)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension ProcessReport {

    public enum CompareOptions: CaseIterable, Hashable, Sendable {

      case traffic
      case speed
      case name

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

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension Array where Element == ProcessReport {

    @MainActor public func sorted(using options: ProcessReport.CompareOptions) -> [ProcessReport] {
      switch options {
      case .traffic:
        return self.sorted { lhs, rhs in
          lhs.transactionMetrics.totalBytesReceived > rhs.transactionMetrics.totalBytesReceived
        }
      case .speed:
        return self.sorted { lhs, rhs in
          lhs.transactionMetrics.bytesReceived > rhs.transactionMetrics.bytesReceived
        }
      case .name:
        return self.sorted(using: SortDescriptor(\.processName))
      }
    }
  }

  #if DEBUG
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    extension ProcessReport {
      @MainActor public static let exampleData = [
        ProcessReport(
          processName: "Xcode",
          processBundleURL: URL(filePath: "/Applications/Xcode-beta.app/"),
          processExecutableURL: URL(filePath: "/Applications/Xcode-beta.app/Contents/MacOS/Xcode"),
          processIconTIFFRepresentation: nil,
          transactionMetrics: .init(
            totalBytesReceived: .init(value: 75231, unit: .bytes),
            totalBytesSent: .init(value: 18333, unit: .bytes),
            bytesReceived: .init(value: 0, unit: .bytes),
            bytesSent: .init(value: 0, unit: .bytes),
            countOfActiveConnections: 1,
            connections: [1752, 2190, 2191],
            processIdentifiers: [60284]
          )
        )
      ]
    }
  #endif
#endif
