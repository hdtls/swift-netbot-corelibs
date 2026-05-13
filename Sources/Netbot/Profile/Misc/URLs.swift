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
  import FoundationEssentials
#else
  import Foundation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URL {

  #if !canImport(Darwin)
    public static var applicationSupportDirectory: URL {
      .homeDirectory.appending(path: ".local")
    }

    public static var cachesDirectory: URL {
      .homeDirectory.appending(path: ".cache")
    }
  #endif

  /// Container URL for security application group.
  public static var securityApplicationGroupDirectory: URL {
    #if canImport(Darwin)
      FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.tenbits.netbot")!
    #else
      URL.homeDirectory.appending(
        path: ".local/share/group.com.tenbits.netbot", directoryHint: .isDirectory)
    #endif
  }

  /// URL for Default profile in file system.
  public static var profile: URL {
    #if canImport(Darwin)
      let pathComponent = "Library/Application Support/Netbot/Profiles/Default.netbotcfg"
    #else
      let pathComponent = "Profiles/Default.netbotcfg"
    #endif
    return
      securityApplicationGroupDirectory
      .appending(component: pathComponent, directoryHint: .notDirectory)
  }

  /// MaxMind databases directory.
  public static var maxmind: URL {
    #if !DEBUG
      let pathComponent = "\(Bundle.main.bundleIdentifier!)/MaxMindDB"
    #else
      let pathComponent = "com.tenbits.netbot.packet-tunnel.extension/MaxMindDB"
    #endif
    return .applicationSupportDirectory
      .appending(component: pathComponent, directoryHint: .isDirectory)
  }

  /// External resource directory in group container.
  public static var externalResourceDirectory: URL {
    #if !DEBUG
      let pathComponent = "\(Bundle.main.bundleIdentifier!)/External Resource"
    #else
      let pathComponent = "com.tenbits.netbot.packet-tunnel.extension/External Resource"
    #endif
    return .applicationSupportDirectory
      .appending(component: pathComponent, directoryHint: .isDirectory)
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension String {

  package static var profilePathExtension: String { "netbotcfg" }
}
