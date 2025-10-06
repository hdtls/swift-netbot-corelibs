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
  import AppKit
  import Darwin
  import Foundation
  import SecurityFoundation
  import os
  import SystemConfiguration

  /// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the
  /// service to make it available to the process hosting the service over an NSXPCConnection.
  @available(SwiftStdlib 5.3, *)
  public class PHTHandle {

    private let listener: NSXPCListener

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "com.apple.xpc")

    public init(listener: NSXPCListener) {
      self.listener = listener
    }

    /// Connection code signing requirement.
    public func codeSigningRequirement() -> String {
      if #available(SwiftStdlib 5.7, *) {
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
      } else {
        // TODO: Fallback to SwiftStdlib 5.3
        return ""
      }
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

  @available(SwiftStdlib 5.3, *)
  extension PHTHandle: @unchecked Sendable {}

  @available(SwiftStdlib 5.3, *)
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

        guard SCNetworkProtocolSetConfiguration(protocolProxies, options.options as CFDictionary)
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
      func processInfo(processIdentifier: pid_t) -> ProcessInfo {
        let processInfo = ProcessInfo()
        processInfo.processIdentifier = processIdentifier

        if let app = NSRunningApplication(processIdentifier: processIdentifier) {
          processInfo.processName = app.localizedName
          processInfo.processBundleURL = app.bundleURL
          processInfo.processExecutableURL = app.executableURL
        } else {
          // Because the pbi_name may be truncated to 31 chars, so when
          // length of pbi_name is great than 31, we will move to use the
          // last component of executable path as process name.
          var bsdinfo = proc_bsdinfo()
          let size = proc_pidinfo(
            processIdentifier, PROC_PIDTBSDINFO, 0, &bsdinfo,
            Int32(MemoryLayout<proc_bsdinfo>.stride)
          )
          if size == MemoryLayout<proc_bsdinfo>.stride {
            processInfo.processName = withUnsafeBytes(of: &bsdinfo.pbi_name) {
              String(cString: $0.bindMemory(to: CChar.self).baseAddress!)
            }
          }

          // swift-format-ignore: AlwaysUseLowerCamelCase
          let PROC_PIDPATHINFO_MAXSIZE: UInt32 = 4096
          var buffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
          if proc_pidpath(processIdentifier, &buffer, PROC_PIDPATHINFO_MAXSIZE) > 0 {
            let filePath = String(cString: buffer, encoding: .utf8) ?? ""
            if #available(SwiftStdlib 5.7, *) {
              processInfo.processExecutableURL = filePath.isEmpty ? nil : URL(filePath: filePath)
            } else {
              processInfo.processExecutableURL =
                filePath.isEmpty
                ? nil
                : URL(
                  fileURLWithPath: filePath
                )
            }
            if processInfo.processName == nil || (processInfo.processName?.count ?? 0) >= 31 {
              processInfo.processName = processInfo.processExecutableURL?.lastPathComponent
            }
          }
        }
        return processInfo
      }

      var listpids = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
      guard listpids > 0 else {
        return nil
      }

      let capacity = Int(listpids)
      let pids = UnsafeMutablePointer<pid_t>.allocate(capacity: capacity)
      defer { pids.deallocate() }

      listpids = proc_listpids(UInt32(PROC_ALL_PIDS), 0, pids, Int32(capacity))

      for i in 0..<Int(listpids) {
        let processIdentifier = pids[i]
        guard processIdentifier > 0 else {
          continue
        }

        var size = Int(proc_pidinfo(processIdentifier, PROC_PIDLISTFDS, 0, nil, 0))
        guard size > 0 else {
          continue
        }

        let buffer = UnsafeMutablePointer<proc_fdinfo>.allocate(
          capacity: size / MemoryLayout<proc_fdinfo>.stride
        )
        defer { buffer.deallocate() }

        size =
          Int(proc_pidinfo(processIdentifier, PROC_PIDLISTFDS, 0, buffer, Int32(size)))
          / MemoryLayout<proc_fdinfo>.stride

        for i in 0..<size {
          guard buffer[i].proc_fdtype == PROX_FDTYPE_SOCKET else {
            continue
          }

          var fdinfo = socket_fdinfo()
          let rc = proc_pidfdinfo(
            processIdentifier, buffer[i].proc_fd, PROC_PIDFDSOCKETINFO, &fdinfo,
            Int32(MemoryLayout<socket_fdinfo>.stride))
          guard rc > 0 else {
            continue
          }

          switch fdinfo.psi.soi_protocol {
          case IPPROTO_TCP:
            let lport = UInt16(
              truncatingIfNeeded: fdinfo.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport
            ).bigEndian
            guard lport == address else {
              continue
            }
            return processInfo(processIdentifier: processIdentifier)
          case IPPROTO_UDP:
            let lport = UInt16(truncatingIfNeeded: fdinfo.psi.soi_proto.pri_in.insi_lport).bigEndian
            guard lport == address else {
              continue
            }
            return processInfo(processIdentifier: processIdentifier)
          default:
            continue
          }
        }
      }
      return nil
    }
  }
#endif
