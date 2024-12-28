//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation
  import Security

  enum AuthorizationRightPresets: CaseIterable, Sendable {

    case systemVPNModification

    case systemNetworkingModification

    private var name: String {
      switch self {
      case .systemVPNModification:
        return "com.tenbits.netbot.system-vpn-modification"
      case .systemNetworkingModification:
        return "com.tenbits.netbot.system-networking-modification"
      }
    }

    private var definition: String {
      switch self {
      case .systemVPNModification:
        return kAuthorizationRuleAuthenticateAsAdmin
      case .systemNetworkingModification:
        return kAuthorizationRuleAuthenticateAsAdmin
      }
    }

    private var description: String {
      switch self {
      case .systemVPNModification:
        // All network activity on this Mac may be filtered or monitered when using VPN.
        return String(localized: "\"Netbot\" Would Like to Add VPN Configurations")
      case .systemNetworkingModification:
        return String(localized: "Netbot is trying to modify the system network configuration.")
      }
    }

    private init?(rawValue: String) {
      switch rawValue {
      case NSStringFromSelector(
        #selector((any HelperToolHandleProtocol).systemVPNAuthorizationRights(authentication:))):
        self = .systemVPNModification
      case NSStringFromSelector(
        #selector(
          (any HelperToolHandleProtocol).systemNetworkingAuthorizationRights(authentication:))
      ):
        self = .systemNetworkingModification
      default:
        return nil
      }
    }

    static func authorizationItem(identified selector: Selector) -> AuthorizationItem? {
      guard
        let authorizationRightPresets = AuthorizationRightPresets(
          rawValue: NSStringFromSelector(selector))
      else {
        return nil
      }

      let authorizationItem = authorizationRightPresets.name.withCString {
        AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0)
      }
      return authorizationItem
    }

    static func setupAuthorizationRights(_ authorizationRef: AuthorizationRef) {
      for right in AuthorizationRightPresets.allCases {
        var errorCode = right.name.withCString {
          AuthorizationRightGet($0, nil)
        }

        guard errorCode == errAuthorizationDenied else {
          // A right already exists (err == noErr) or any other error occurs, we
          // assume that it has been set up in advance by the system administrator or
          // this is the second time we've run.  Either way, there's nothing more for
          // us to do.
          return
        }

        errorCode = right.name.withCString {
          AuthorizationRightSet(
            authorizationRef,
            $0,
            right.definition as CFTypeRef,
            right.description as CFString,
            nil,
            String(describing: AuthorizationRightPresets.self) as CFString
          )
        }
        assert(errorCode == errAuthorizationSuccess)
      }
    }
  }
#endif
