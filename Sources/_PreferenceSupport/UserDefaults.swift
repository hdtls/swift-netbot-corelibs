//
// See LICENSE.txt for license information
//

// swift-format-ignore-file

#if canImport(FoundationEssentials)
  import class Foundation.UserDefaults
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
public enum Prefs {
  public enum Name {}
}

@available(SwiftStdlib 5.3, *)
extension UserDefaults {

  /// Returns UserDefaults(suiteName: "group.com.tenbits.netbot.testable") when debug with --testable else return a global
  /// instance of UserDefaults configured to search the shared application group's search list.
  public class var `__shared`: UserDefaults? {
    UserDefaults(suiteName: "group.\(__suiteName)")
  }

  /// Return `UserDefaults(suiteName: __suiteName)` when debug with --testable else return standard defaults.
  public class var __standard: UserDefaults? {
    #if DEBUG
      guard CommandLine.arguments.contains("--testable") else {
        return .standard
      }
      return UserDefaults(suiteName: __suiteName)
    #else
      .standard
    #endif
  }
}

public var __suiteName: String {
  #if DEBUG
    guard CommandLine.arguments.contains("--testable") else {
      return "com.tenbits.netbot"
    }
    return "com.tenbits.netbot.testable"
  #else
    "com.tenbits.netbot"
  #endif
}
