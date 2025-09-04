//
// See LICENSE.txt for license information
//

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

  /// Returns a global instance of UserDefaults configured to search the shared application group's search list.
  public class var applicationGroup: UserDefaults? {
    UserDefaults(suiteName: "group.com.tenbits.netbot")
  }
}
