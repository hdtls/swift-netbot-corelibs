//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import RegexBuilder

@available(SwiftStdlib 5.3, *)
extension AnyProxyGroup {

  public static let sectionName = "[Proxy Group]"

  @available(SwiftStdlib 5.7, *)
  public static var regex: Regex<(Substring, Substring, AnyProxyGroup.Kind, Substring)> {
    Regex {
      /([^=\n]+) *= */
      TryCapture {
        try! Regex<Substring>(
          AnyProxyGroup.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        AnyProxyGroup.Kind(rawValue: String($0))
      }

      // Capture policy resource.
      /\, *(.+) */
    }
  }
}
