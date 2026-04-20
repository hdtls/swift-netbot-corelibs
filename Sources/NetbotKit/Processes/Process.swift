// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

#if os(macOS)
  import NetbotLiteData
  import Dashboard
  import Foundation

  @available(SwiftStdlib 5.9, *)
  extension Program.Model {

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
  extension Array where Element == Program.Model {

    @MainActor public func sorted(using options: Program.Model.CompareOptions)
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
