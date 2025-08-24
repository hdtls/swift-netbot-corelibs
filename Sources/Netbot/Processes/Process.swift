//
// See LICENSE.txt for license information
//

#if os(macOS)
  import AnlzrReports
  import Dashboard
  import Foundation

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension Program.PersistentModel {

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

    public var formattedPIDs: String {
      processReports
        .compactMap(\.processIdentifier?.description)
        .removeDuplicates()
        .joined(separator: ", ")
    }

    public var hostname: String {
      processReports
        .compactMap { $0.connection }
        .sorted { lhs, rhs in
          (lhs.dataTransferReport?.aggregatePathReport.receivedApplicationByteCount ?? 0)
            > (rhs.dataTransferReport?.aggregatePathReport.receivedApplicationByteCount ?? 0)
        }
        .first?.currentRequest?.hostname ?? ""
    }

    public func dataTransferred(direction: TrafficDirection) -> Measurement<UnitInformationStorage>
    {
      switch direction {
      case .outbound:
        return Measurement(
          value: Double(dataTransferReport?.aggregatePathReport.sentApplicationByteCount ?? 0),
          unit: .bytes
        )
      case .inbound:
        return Measurement(
          value: Double(dataTransferReport?.aggregatePathReport.receivedApplicationByteCount ?? 0),
          unit: .bytes
        )
      }
    }

    public func transmissionRate(direction: TrafficDirection) -> Measurement<UnitInformationStorage>
    {
      switch direction {
      case .outbound:
        return Measurement(
          value: Double(dataTransferReport?.pathReports.first?.sentApplicationByteCount ?? 0),
          unit: .bytes
        )
      case .inbound:
        return Measurement(
          value: Double(dataTransferReport?.pathReports.first?.receivedApplicationByteCount ?? 0),
          unit: .bytes
        )
      }
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension Array where Element == Program.PersistentModel {

    @MainActor public func sorted(using options: Program.PersistentModel.CompareOptions)
      -> [Element]
    {
      switch options {
      case .traffic:
        return self.sorted { lhs, rhs in
          lhs.dataTransferred(direction: .inbound) > rhs.dataTransferred(direction: .inbound)
        }
      case .speed:
        return self.sorted { lhs, rhs in
          lhs.transmissionRate(direction: .inbound) > rhs.transmissionRate(direction: .inbound)
        }
      case .name:
        return self.sorted(using: SortDescriptor(\.localizedName))
      }
    }
  }
#endif
