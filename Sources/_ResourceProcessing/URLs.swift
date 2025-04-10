//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

extension URL {

  /// Container URL for security application group.
  public static var applicationGroupDirectory: URL {
    #if canImport(Darwin)
      FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.tenbits.netbot")!
    #else
      URL.homeDirectory.appending(path: ".com.tenbits.netbot", directoryHint: .isDirectory)
    #endif
  }

  /// URL for Default profile in file system.
  public static var profile: URL {
    #if canImport(Darwin)
      let pathComponent = "Library/Application Support/Netbot/Profiles"
    #else
      let pathComponent = "Profiles"
    #endif
    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      return applicationGroupDirectory.appending(component: pathComponent)
        .appending(path: "Default").appendingPathExtension(.profilePathExtension)
    } else {
      return applicationGroupDirectory.appendingPathComponent(pathComponent)
        .appending(path: "Default").appendingPathExtension(.profilePathExtension)
    }
  }

  /// MaxMind databases directory in group container.
  public static var maxmind: URL {
    #if canImport(Darwin)
      let pathComponent = "Library/Application Support/Netbot/MaxMindDB"
    #else
      let pathComponent = "MaxMindDB"
    #endif
    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      return applicationGroupDirectory.appending(
        component: pathComponent, directoryHint: .isDirectory)
    } else {
      return applicationGroupDirectory.appendingPathComponent(pathComponent, isDirectory: true)
    }
  }

  /// External resource directory in group container.
  public static var externalResourceDirectory: URL {
    #if canImport(Darwin)
      let pathComponent = "Library/Caches/Netbot/External Resource"
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        return applicationGroupDirectory.appending(
          component: pathComponent, directoryHint: .isDirectory)
      } else {
        return applicationGroupDirectory.appendingPathComponent(pathComponent, isDirectory: true)
      }
    #else
      return URL.homeDirectory.appending(
        components: ".cache", "com.tenbits.netbot", "External Resource")
    #endif
  }
}

extension String {

  package static var profilePathExtension: String { "netbotcfg" }
}
