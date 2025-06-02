//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
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
      URL.homeDirectory.appending(path: ".local/share/Netbot", directoryHint: .isDirectory)
    #endif
  }

  /// URL for Default profile in file system.
  public static var profile: URL {
    #if canImport(Darwin)
      let pathComponent = "Library/Application Support/Netbot/Profiles/Default.netbotcfg"
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        return
          securityApplicationGroupDirectory
          .appending(component: pathComponent, directoryHint: .notDirectory)
      } else {
        return
          securityApplicationGroupDirectory
          .appendingPathComponent(pathComponent, isDirectory: false)
      }
    #else
      let pathComponent = "Profiles/Default.netbotcfg"
      return
        securityApplicationGroupDirectory
        .appending(component: pathComponent, directoryHint: .notDirectory)
    #endif
  }

  /// MaxMind databases directory.
  public static var maxmind: URL {
    #if !DEBUG
      let pathComponent = "\(Bundle.main.bundleIdentifier!)/MaxMindDB"
    #else
      let pathComponent = "com.tenbits.netbot.packet-tunnel.extension/MaxMindDB"
    #endif
    #if canImport(Darwin)
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        return .applicationSupportDirectory
          .appending(component: pathComponent, directoryHint: .isDirectory)
      } else {
        // applicationSupportDirectory always exists on Apple platforms.
        let applicationSupportDirectory = try! FileManager.default.url(
          for: .applicationSupportDirectory,
          in: .userDomainMask,
          appropriateFor: nil,
          create: false
        )
        return applicationSupportDirectory.appendingPathComponent(pathComponent, isDirectory: true)
      }
    #else
      return .applicationSupportDirectory
        .appending(component: pathComponent, directoryHint: .isDirectory)
    #endif
  }

  /// External resource directory in group container.
  public static var externalResourceDirectory: URL {
    #if !DEBUG
      let pathComponent = "\(Bundle.main.bundleIdentifier!)/External Resource"
    #else
      let pathComponent = "com.tenbits.netbot.packet-tunnel.extension/External Resource"
    #endif
    #if canImport(Darwin)
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        return .applicationSupportDirectory
          .appending(component: pathComponent, directoryHint: .isDirectory)
      } else {
        // applicationSupportDirectory always exists on Apple platforms.
        let applicationSupportDirectory = try! FileManager.default.url(
          for: .applicationSupportDirectory,
          in: .userDomainMask,
          appropriateFor: nil,
          create: false
        )
        return applicationSupportDirectory.appendingPathComponent(pathComponent, isDirectory: true)
      }
    #else
      return .applicationSupportDirectory
        .appending(component: pathComponent, directoryHint: .isDirectory)
    #endif
  }
}

extension String {

  package static var profilePathExtension: String { "netbotcfg" }
}
