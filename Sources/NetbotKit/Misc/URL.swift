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

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import struct Foundation.URLResourceKey
#else
  import Foundation
#endif

#if !canImport(FoundationEssentials)
  @available(SwiftStdlib 5.7, *)
  extension ParseableFormatStyle where Self == URL.FormatStyle {

    public static var _url: URL.FormatStyle {
      .init(path: .omitWhen(.path, matches: ["/"]), query: .omitWhen(.query, matches: [""]))
    }
  }
#endif

@available(SwiftStdlib 5.3, *)
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
