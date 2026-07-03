// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if canImport(FoundationEssentials)
  import class Foundation.UserDefaults
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
public enum Prefs {
  public enum Name {}
}

@available(SwiftStdlib 6.0, *)
extension UserDefaults {

  /// Returns a global instance of UserDefaults configured to search the shared application group's search list.
  public class var shared: UserDefaults? {
    UserDefaults(suiteName: "group.com.tenbits.netbot")
  }
}
