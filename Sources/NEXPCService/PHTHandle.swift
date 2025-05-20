//
// See LICENSE.txt for license information
//

#if os(macOS)
  import AppKit
  import Darwin
  import Foundation
  import SecurityFoundation
  import os
  import SystemConfiguration

  /// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the
  /// service to make it available to the process hosting the service over an NSXPCConnection.
  public class PHTHandle {

    private let listener: NSXPCListener

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "com.apple.xpc")

    public init(listener: NSXPCListener) {
      self.listener = listener
    }

    /// Connection code signing requirement.
    public func codeSigningRequirement() -> String {
      var codeSigningRequirementParts: [Substring] = []

      let propertyList =
        Bundle.main.object(forInfoDictionaryKey: "SMAuthorizedClients") as! [String]
      let authorizedClients =
        propertyList
        .map {
          $0.split(separator: /\ and\ /)
            .filter { $0.starts(with: /^identifier\ /) }
        }
        .joined()
      codeSigningRequirementParts.append(contentsOf: authorizedClients)

      codeSigningRequirementParts.append("anchor apple generic")

      let team = propertyList.first.map {
        $0.split(separator: /\ and\ /)
          .filter { $0.starts(with: /^certificate leaf\[subject\./) }
          .first!
      }!
      codeSigningRequirementParts.append(team)

      return codeSigningRequirementParts.joined(separator: " and ")
    }

    /// Check that the client denoted by authorization is allowed to run the specified command.
    /// authorization is expected to be an Data with an AuthorizationExternalForm embedded inside.
    private func checkValidity(authentication: Data, selector: Selector) throws {
      var err = errAuthorizationSuccess
      var junk: OSStatus?
      var authorizationRef: AuthorizationRef?

      // First check that authorization looks reasonable.
      guard authentication.count == MemoryLayout<AuthorizationExternalForm>.size else {
        let error = NSError(domain: NSOSStatusErrorDomain, code: paramErr)
        throw error
      }

      // Create an authorization ref from that the external form data contained within.
      err = authentication.withUnsafeBytes {
        guard let extForm = $0.bindMemory(to: AuthorizationExternalForm.self).baseAddress else {
          return OSStatus(paramErr)
        }
        return AuthorizationCreateFromExternalForm(extForm, &authorizationRef)
      }

      // Authorize the right associated with the command.

      guard err == errAuthorizationSuccess else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(err))
      }

      guard let authorizationRef else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(errAuthorizationInvalidRef))
      }

      guard
        var authorizationItem = AuthorizationPresets.authorizationItem(identified: selector)
      else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(errAuthorizationDenied))
      }

      var authorizationRights = withUnsafeMutablePointer(to: &authorizationItem) {
        AuthorizationRights(count: 1, items: $0)
      }
      err = AuthorizationCopyRights(
        authorizationRef,
        &authorizationRights,
        nil,
        [.extendRights, .interactionAllowed, .preAuthorize],
        nil
      )

      junk = AuthorizationFree(authorizationRef, .init(rawValue: 0))
      assert(junk == errAuthorizationSuccess)
    }
  }

  extension PHTHandle: @unchecked Sendable {}

  extension PHTHandle: PHTHandleProtocol {

    public func listenerEndpoint() async -> NSXPCListenerEndpoint {
      listener.endpoint
    }

    public func toolVersion() async -> String {
      // We specifically don't check for authorization here.  Everyone is always allowed to get
      // the version of the helper tool.
      Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    public func setNWProtocolProxies(processName: String, options: NEProtocolProxies.Options)
      async throws
    {
      guard let prefs = SCPreferencesCreate(nil, processName as CFString, nil) else {
        throw SCCopyLastError()
      }

      guard let networkSet = SCNetworkSetCopyCurrent(prefs),
        let networkServices = SCNetworkSetCopyServices(networkSet) as? [SCNetworkService]
      else {
        return
      }

      for service in networkServices {
        guard let serviceName = SCNetworkServiceGetName(service) as? String else {
          continue
        }
        guard ["AirPort", "Wi-Fi", "Ethernet"].contains(serviceName) else {
          continue
        }

        guard
          let protocolProxies = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies)
        else {
          continue
        }

        var optionsDictionary =
          SCNetworkProtocolGetConfiguration(protocolProxies) as? [CFString: Any] ?? [:]
        optionsDictionary.merge(options.options, uniquingKeysWith: { _, rhs in rhs })

        guard SCNetworkProtocolSetConfiguration(protocolProxies, optionsDictionary as CFDictionary)
        else {
          throw SCCopyLastError()
        }
      }

      guard SCPreferencesCommitChanges(prefs) else {
        throw SCCopyLastError()
      }

      SCPreferencesSynchronize(prefs)

      guard SCPreferencesApplyChanges(prefs) else {
        throw SCCopyLastError()
      }
    }

    public func processInfo(address: UInt16) async throws -> ProcessInfo? {
      for app in NSWorkspace.shared.runningApplications {
        var size = Int(proc_pidinfo(app.processIdentifier, PROC_PIDLISTFDS, 0, nil, 0))
        guard size > 0 else {
          continue
        }

        let buffer = UnsafeMutablePointer<proc_fdinfo>.allocate(
          capacity: size / MemoryLayout<proc_fdinfo>.stride
        )
        defer { buffer.deallocate() }

        size =
          Int(proc_pidinfo(app.processIdentifier, PROC_PIDLISTFDS, 0, buffer, Int32(size)))
          / MemoryLayout<proc_fdinfo>.stride

        for i in 0..<size {
          guard buffer[i].proc_fdtype == PROX_FDTYPE_SOCKET else {
            continue
          }

          var fdinfo = socket_fdinfo()
          let rc = proc_pidfdinfo(
            app.processIdentifier,
            buffer[i].proc_fd,
            PROC_PIDFDSOCKETINFO,
            &fdinfo,
            Int32(MemoryLayout<socket_fdinfo>.stride)
          )
          guard rc > 0 else {
            continue
          }

          switch fdinfo.psi.soi_kind {
          case Int32(SOCKINFO_TCP):
            let lport = UInt16(
              truncatingIfNeeded: fdinfo.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport)
            if lport.bigEndian == address {
              let processInfo = ProcessInfo()
              processInfo.processName = app.localizedName ?? ""
              processInfo.processBundleURL = app.bundleURL
              processInfo.processExecutableURL = app.executableURL
              processInfo.processIdentifier = app.processIdentifier
              processInfo.processIconTIFFRepresentation = app.icon?.tiffRepresentation
              return processInfo
            }
          default:
            continue
          }
        }
      }
      return nil
    }
  }
#endif
