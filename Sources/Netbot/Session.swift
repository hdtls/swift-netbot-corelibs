//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Foundation
  import Logging
  @preconcurrency import NetworkExtension

  /// NETunnelProviderSession wrapper.
  @available(SwiftStdlib 5.3, *)
  @globalActor public actor Session {

    public static let shared = Session()

    public enum Message: Sendable {
      case data(Data)
      case string(String)
    }

    nonisolated public let logger = Logger(label: "Session")

    private var manager: NETunnelProviderManager?
    private var lastLoadError: Error?
    private var managerLoadingTask: Task<Void, any Error>?

    private var processName: String {
      ProcessInfo.processInfo.processName
    }

    private init() {}

    /// Start packet tunnel with specific options.
    public func startVPNTunnel(options: [String: Any]) async throws {
      do {
        try await waitUntilLoaded()
        assert(manager != nil)

        logger.trace("\(processName) VPN session start...")
        let session = manager?.connection as? NETunnelProviderSession
        try session?.startTunnel()
        logger.trace("\(processName) VPN session start successfully")
      } catch {
        logger.error("\(processName) VPN session start failure with error: \(error)")
        lastLoadError = error
        throw error
      }
    }

    /// Stop current running packet tunnel.
    public func stopVPNTunnel() async {
      let session = manager?.connection as? NETunnelProviderSession
      session?.stopTunnel()
      manager = nil
      managerLoadingTask?.cancel()
      managerLoadingTask = nil
      lastLoadError = nil
    }

    @discardableResult
    nonisolated public func send(_ message: Message) async throws -> Data? {
      guard let session = await manager?.connection as? NETunnelProviderSession else {
        return nil
      }

      return try await withCheckedThrowingContinuation { continuation in
        do {
          let finalize: Data
          switch message {
          case .data(let data):
            finalize = data
          case .string(let string):
            finalize = string.data(using: .utf8) ?? Data()
          }
          try session.sendProviderMessage(finalize) {
            continuation.resume(returning: $0)
          }
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }

    private func waitUntilLoaded() async throws {
      if let task = managerLoadingTask {
        try await task.value
      }
      // You load the manager at once, so you can skip this if the
      // loadedManager is nil.
      else if manager == nil {
        let newTask = Task {
          do {
            let bundleID = "com.tenbits.netbot.packet-tunnel.extension"
            let manager =
              try await NETunnelProviderManager.loadAllFromPreferences().first {
                guard let configuration = $0.protocolConfiguration as? NETunnelProviderProtocol
                else {
                  return false
                }
                return configuration.providerBundleIdentifier == bundleID
              } ?? NETunnelProviderManager()

            let configuration = NETunnelProviderProtocol()
            configuration.serverAddress = "127.0.0.1"
            configuration.providerBundleIdentifier = bundleID
            manager.protocolConfiguration = configuration
            manager.localizedDescription = processName
            manager.isEnabled = true
            manager.isOnDemandEnabled = true

            #if os(macOS)
              var authorizationRef: AuthorizationRef?
              let authFlags: AuthorizationFlags = [
                .extendRights, .interactionAllowed, .preAuthorize,
              ]
              let error = AuthorizationCreate(nil, nil, authFlags, &authorizationRef)
              if error == noErr, let authorizationRef {
                manager.setAuthorization(authorizationRef)
              }
            #endif

            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            self.manager = manager
          } catch {
            throw error
          }
          managerLoadingTask = nil
        }
        managerLoadingTask = newTask
        try await newTask.value
      }
    }
  }
#endif
