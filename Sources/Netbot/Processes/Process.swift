//
// See LICENSE.txt for license information
//

#if os(macOS)
  import AnlzrReports
  import Foundation
  import SwiftData

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
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension Array where Element == Program.PersistentModel {

    @MainActor public func sorted(using options: Program.CompareOptions) -> [Element] {
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
        return self.sorted(using: SortDescriptor(\.localizedName))
      }
    }
  }
#endif
