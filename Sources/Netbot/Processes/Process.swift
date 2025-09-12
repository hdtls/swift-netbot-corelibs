//
// See LICENSE.txt for license information
//

#if os(macOS)
  import AnlzrReports
  import Dashboard
  import Foundation

  @available(SwiftStdlib 5.9, *)
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
          (lhs.dataTransferReport?.aggregatePathReport?.receivedApplicationByteCount ?? 0)
            > (rhs.dataTransferReport?.aggregatePathReport?.receivedApplicationByteCount ?? 0)
        }
        .first?.currentRequest?.hostname ?? ""
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension Array where Element == Program.PersistentModel {

    @MainActor public func sorted(using options: Program.PersistentModel.CompareOptions)
      -> [Element]
    {
      switch options {
      case .traffic:
        return self.sorted { lhs, rhs in
          lhs.dataTransferReport?.aggregatePathReport?.receivedApplicationByteCount ?? 0 > rhs
            .dataTransferReport?.aggregatePathReport?.receivedApplicationByteCount ?? 0
        }
      case .speed:
        return self.sorted { lhs, rhs in
          lhs.dataTransferReport?.pathReport?.receivedApplicationByteCount ?? 0 > rhs
            .dataTransferReport?.pathReport?.receivedApplicationByteCount ?? 0
        }
      case .name:
        return self.sorted(using: SortDescriptor(\.localizedName))
      }
    }
  }
#endif
