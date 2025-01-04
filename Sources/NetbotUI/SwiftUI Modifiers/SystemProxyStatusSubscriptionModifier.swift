//
// See LICENSE.txt for license information
//

import SwiftUI

#if os(macOS)
  import Logging
  import Netbot
  import SwiftData
  import SystemConfiguration

  @MainActor private class Configurator {

    struct Arguments: Equatable {
      var socksListenAddress = ""
      var socksListenPort: Int?
      var httpListenAddress = ""
      var httpListenPort: Int?
      var exceptions: [String] = []
      var excludeSimpleHostnames = false

      var settings: CFDictionary {
        var settings: [CFString: Any] = [:]
        if let port = socksListenPort {
          settings[kCFNetworkProxiesSOCKSProxy] = socksListenAddress
          settings[kCFNetworkProxiesSOCKSPort] = port
          settings[kCFNetworkProxiesSOCKSEnable] = 1
        }

        if let port = httpListenPort {
          settings[kCFNetworkProxiesHTTPProxy] = httpListenAddress
          settings[kCFNetworkProxiesHTTPPort] = port
          settings[kCFNetworkProxiesHTTPEnable] = 1
          settings[kCFNetworkProxiesHTTPSProxy] = httpListenAddress
          settings[kCFNetworkProxiesHTTPSPort] = port
          settings[kCFNetworkProxiesHTTPSEnable] = 1
        }

        settings[kCFNetworkProxiesExcludeSimpleHostnames] = excludeSimpleHostnames ? 1 : 0
        settings[kCFNetworkProxiesExceptionsList] = exceptions
        return settings as CFDictionary
      }
    }

    static let shared = Configurator()

    private var arguments: Arguments?
    private var preferences: SCPreferences?
    private let logger = Logger(label: "com.apple.SystemConfiguration")

    func saveToPreferences(arguments: Arguments?) {
      guard arguments != self.arguments else {
        return
      }
      self.arguments = arguments
      let settings = arguments?.settings ?? [:] as CFDictionary

      if preferences == nil {
        authorize()
      }
      guard let prefs = preferences else { return }

      guard let networkSet = SCNetworkSetCopyCurrent(prefs),
        let networkServices = SCNetworkSetCopyServices(networkSet) as? [SCNetworkService]
      else {
        return
      }

      let paths: [CFString] = networkServices.compactMap { service in
        guard let serviceName = SCNetworkServiceGetName(service) as? String else {
          return nil
        }
        guard ["AirPort", "Wi-Fi", "Ethernet"].contains(serviceName) else {
          return nil
        }

        guard let serviceID = SCNetworkServiceGetServiceID(service) else {
          return nil
        }

        return "/\(kSCPrefNetworkServices)/\(serviceID)/\(kSCEntNetProxies)" as CFString
      }
      guard !paths.isEmpty else {
        return
      }
      for path in paths {
        SCPreferencesPathSetValue(prefs, path as CFString, settings)
      }

      guard SCPreferencesCommitChanges(prefs) else {
        logger.critical(
          "Failed to commit system network preferences changes, error: \(SCCopyLastError().localizedDescription)"
        )
        return
      }

      SCPreferencesSynchronize(prefs)

      guard SCPreferencesApplyChanges(prefs) else {
        logger.critical(
          "Failed to apply system network preferences changes, error: \(SCCopyLastError().localizedDescription)"
        )
        return
      }

      logger.trace("System network preferences has been updated successfully")
    }

    private func authorize() {
      var authRef: AuthorizationRef!
      let authFlags: AuthorizationFlags = [
        .extendRights, .interactionAllowed, .preAuthorize,
      ]
      let authError = AuthorizationCreate(nil, nil, authFlags, &authRef)

      guard authError == noErr, authRef != nil else {
        logger.critical("No authorization has been granted to modify network configuration")
        return
      }

      let processName = ProcessInfo.processInfo.processName as CFString

      guard let prefs = SCPreferencesCreateWithAuthorization(nil, processName, nil, authRef) else {
        logger.error(
          "Failed to create system configuration preferences, error: \(SCCopyLastError().localizedDescription)"
        )
        return
      }

      preferences = prefs
    }
  }
#endif

private struct SystemProxyStatusSubscriptionModifier: ViewModifier {

  #if os(macOS)
    @AppStorage(Prefs.Name.enableSystemProxy) private var enableSystemProxy = false
    @Query private var profiles: [Profile.PersistentModel]
    @State private var arguments: Configurator.Arguments?
    private let configurator = Configurator.shared
  #endif

  func body(content: Content) -> some View {
    content
      #if os(macOS)
        .onChange(of: profiles) { _, newValue in
          guard let profile = newValue.first else {
            arguments = nil
            return
          }
          arguments = Configurator.Arguments(
            socksListenAddress: profile.socksListenAddress,
            socksListenPort: profile.socksListenPort,
            httpListenAddress: profile.httpListenAddress,
            httpListenPort: profile.httpListenPort,
            exceptions: profile.exceptions,
            excludeSimpleHostnames: profile.excludeSimpleHostnames
          )
        }
        .onChange(of: enableSystemProxy) {
          guard let profile = profiles.first else {
            arguments = nil
            return
          }

          arguments =
            enableSystemProxy
            ? Configurator.Arguments(
              socksListenAddress: profile.socksListenAddress,
              socksListenPort: profile.socksListenPort,
              httpListenAddress: profile.httpListenAddress,
              httpListenPort: profile.httpListenPort,
              exceptions: profile.exceptions,
              excludeSimpleHostnames: profile.excludeSimpleHostnames
            )
            : nil
        }
        .onChange(of: arguments) { _, newValue in
          configurator.saveToPreferences(arguments: newValue)
        }
      #endif
  }
}

extension View {
  func subscribeToSystemProxyStatus() -> some View {
    modifier(SystemProxyStatusSubscriptionModifier())
  }
}
