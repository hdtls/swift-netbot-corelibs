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

#if os(macOS)
  import Foundation
  import Security

  enum AuthorizationPresets: CaseIterable, Sendable {

    case systemProtocolProxiesModification

    private var name: String {
      switch self {
      case .systemProtocolProxiesModification:
        return "com.tenbits.netbot.system-protocol-proxies-modification"
      }
    }

    private var definition: String {
      switch self {
      case .systemProtocolProxiesModification:
        return kAuthorizationRuleAuthenticateAsAdmin
      }
    }

    private var description: String {
      switch self {
      case .systemProtocolProxiesModification:
        if #available(SwiftStdlib 5.5, *) {
          return String(localized: "Netbot is trying to modify the system network configuration.")
        } else {
          return "Netbot is trying to modify the system network configuration."
        }
      }
    }

    private init?(rawValue: String) {
      switch rawValue {
      default:
        return nil
      }
    }

    static func authorizationItem(identified selector: Selector) -> AuthorizationItem? {
      guard
        let authorizationPresets = AuthorizationPresets(
          rawValue: NSStringFromSelector(selector))
      else {
        return nil
      }

      let authorizationItem = authorizationPresets.name.withCString {
        AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0)
      }
      return authorizationItem
    }

    static func setupAuthorizationRights(_ authorizationRef: AuthorizationRef) {
      for right in AuthorizationPresets.allCases {
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
            String(describing: AuthorizationPresets.self) as CFString
          )
        }
        assert(errorCode == errAuthorizationSuccess)
      }
    }
  }
#endif
