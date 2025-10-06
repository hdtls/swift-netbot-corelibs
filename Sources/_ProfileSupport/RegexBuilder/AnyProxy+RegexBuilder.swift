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
extension AnyProxy {

  public static let sectionName = "[Proxy]"

  @available(SwiftStdlib 5.7, *)
  public static var regex: Regex<(Substring, Substring, AnyProxy.Kind, Substring?)> {
    Regex {
      /([^=\n]+) *= */
      TryCapture {
        try! Regex<Substring>(AnyProxy.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        AnyProxy.Kind(rawValue: String($0))
      }
      /(?:,? *([^\n]+))?/
    }
  }
}
