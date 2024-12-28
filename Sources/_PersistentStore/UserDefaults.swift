//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import class Foundation.UserDefaults
#else
  public import Foundation
#endif

public enum Prefs {
  public enum Name {}
}

extension UserDefaults {

  /// Returns a global instance of UserDefaults configured to search the shared application group's search list.
  public class var applicationGroup: UserDefaults? {
    UserDefaults(suiteName: "group.com.tenbits.netbot")
  }
}
