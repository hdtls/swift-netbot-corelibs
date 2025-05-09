//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation
  import SecurityFoundation
  import os

  /// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the
  /// service to make it available to the process hosting the service over an NSXPCConnection.
  @available(macOS 13.0, *)
  final public class HelperToolHandle: @unchecked Sendable {

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
        var authorizationItem = AuthorizationRightPresets.authorizationItem(identified: selector)
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

  @available(macOS 13.0, *)
  extension HelperToolHandle: AuthorizationHandleProtocol {

    public func systemVPNAuthorizationRights(authentication: Data) async throws -> Data {
      logger.debug("Obtain the authorization to modify the system VPN configurations")
      let selector = #selector(
        (any HelperToolHandleProtocol).systemVPNAuthorizationRights(authentication:))
      do {
        try checkValidity(authentication: authentication, selector: selector)
      } catch {
        logger.error(
          "Obtain the authorization to modify the system VPN configurations failure with error: \(error)"
        )
        throw error
      }
      return authentication
    }

    public func systemNetworkingAuthorizationRights(authentication: Data) async throws -> Data {
      logger.debug("Obtain the authorization to modify the system network settings")
      let selector = #selector(
        (any HelperToolHandleProtocol).systemNetworkingAuthorizationRights(authentication:))
      do {
        try checkValidity(authentication: authentication, selector: selector)
      } catch {
        logger.error(
          "Obtain the authorization to modify the system network settings failure with error: \(error)"
        )
        throw error
      }
      return authentication
    }
  }

  @available(macOS 13.0, *)
  extension HelperToolHandle: HelperToolHandleProtocol {

    public func listenerEndpoint() async -> NSXPCListenerEndpoint {
      listener.endpoint
    }

    public func toolVersion() async -> String {
      // We specifically don't check for authorization here.  Everyone is always allowed to get
      // the version of the helper tool.
      Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }
  }
#endif
