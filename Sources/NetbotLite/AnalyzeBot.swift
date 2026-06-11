// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import Dispatch
import Logging
import NEAddressProcessing
import NEHTTP
import NESOCKS
import NIOCore
import NIOExtras
import NIOHTTP1
import NIOSSL
import NetbotLiteData
import Synchronization
import SynchronizationExtras
import Tracing

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// A `AnalyzeBot` is an easy way to create network proxy servers.
///
/// For current version we support start HTTP and SOCKS as local proxy servers if possible.
@available(SwiftStdlib 6.0, *)
@Lockable public class AnalyzeBot: @unchecked Sendable {

  /// Logger object used to log messages.
  public let logger: Logger

  public typealias NetworkSettings = (SocketAddress, SocketAddress)

  /// Address of web proxy (HTTP/HTTPS) server will bind if present.
  @LockableTracked(accessors: .get)
  final public var webProxyListenAddress: SocketAddress

  /// Address of SOCKS proxy server will bind if present.
  @LockableTracked(accessors: .get)
  final public var socksProxyListenAddress: SocketAddress

  /// The outbound mode control how requests will be process.
  @LockableTracked(accessors: .get)
  final public var outboundMode: OutboundMode = .direct

  /// Forward protocol used in global proxy outbound mode.
  @LockableTracked(accessors: .get)
  final public var forwardProtocol: any ForwardProtocolConvertible = .direct

  /// The rules used to make outbound stream.
  final public var forwardingRules: [any ForwardingRuleConvertible] {
    self.rulesEngine.forwardingRules
  }

  /// A set of enabled capabilities, default is empty.
  @LockableTracked(accessors: .get)
  final public var capabilities: CapabilityFlags = []

  /// The dns resolver.
  @LockableTracked(accessors: .get)
  final public var resolver: any Resolver

  /// The RulesEngine evaluates the Rules.
  @LockableTracked(accessors: .get)
  final public var rulesEngine: any RulesEngine

  /// A service help detect the process that the current connection is created.
  @LockableTracked(accessors: .get)
  final public var processInfo: any ProcessReporting = DefaultProcessReporting()

  /// A publisher publish connection states.
  @LockableTracked(accessors: .get)
  final public var connectionPublisher: any ConnectionPublisher = DefaultConnectionPublisher()

  /// DNS names that allow HTTPS decryption.
  @LockableTracked(accessors: .get)
  final public var decryptionDNSNames: [String] = []

  /// `NIOSSLPKCS12Bundle` used to decrypt HTTPS connections.
  @LockableTracked(accessors: .get)
  final public var decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle? = nil

  /// True if this `AnalyzeBot` is currently active. `isActive` is defined as the period
  /// of time after the `run` and before `shutdownGracefully` has fired.
  @LockableTracked(accessors: .get)
  final public var isActive: Bool = false

  private var quiescing: [ServerQuiescingHelper] = []

  private let eventLoopGroup: any EventLoopGroup

  private var processName: String {
    "AnalyzeBot"
  }

  /// Initialize an instance of `Netbot` with specified settings.
  public init(
    group: any EventLoopGroup,
    logger: Logger,
    webProxyListenAddress: SocketAddress = try! .init(ipAddress: "127.0.0.1", port: 6152),
    socksProxyListenAddress: SocketAddress = try! .init(ipAddress: "127.0.0.1", port: 6153)
  ) {
    self.eventLoopGroup = group
    self.logger = logger
    self.$webProxyListenAddress = .init(webProxyListenAddress)
    self.$socksProxyListenAddress = .init(socksProxyListenAddress)
    self.$resolver = .init(DefaultResolver(eventLoop: group.next()))
    self.$rulesEngine = .init(DefaultRulesEngine(logger: logger))
  }

  /// Modify Web and SOCKS proxy settings.
  public func setTunnelNetworkSettings(_ networkSettings: NetworkSettings) async throws {
    guard networkSettings.0 != webProxyListenAddress || networkSettings.1 != socksProxyListenAddress
    else {
      return
    }

    $webProxyListenAddress.withLock { $0 = networkSettings.0 }
    $socksProxyListenAddress.withLock { $0 = networkSettings.1 }

    if isActive {
      try await shutdownGracefully0()
      try await run0()
    }
  }

  /// Modify outbound mode.
  public func setOutboundMode(_ outboundMode: OutboundMode) async {
    self.$outboundMode.withLock { $0 = outboundMode }
  }

  /// Modify global forward protocol.
  public func setForwardProtocol(_ newForwardProtocol: any ForwardProtocolConvertible) async {
    self.$forwardProtocol.withLock { $0 = newForwardProtocol }
  }

  /// Modify forwarding rules.
  public func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async {
    self.rulesEngine.setForwardingRules(forwardingRules)
  }

  /// Modify enabled HTTP capabilities.
  public func setEnabledHTTPCapabilities(_ enabledHTTPCapabilities: CapabilityFlags) async {
    self.$capabilities.withLock { $0 = enabledHTTPCapabilities }
  }

  /// Modify the DNS resolver.
  public func setResolver(_ resolver: some Resolver) async {
    self.$resolver.withLock { $0 = resolver }
  }

  /// Modify forwarding rules engine.
  public func setRulesEngine(_ rulesEngine: some RulesEngine) async {
    self.$rulesEngine.withLock { $0 = rulesEngine }
  }

  /// Modify default process info detector.
  public func setProcessInfo(_ processInfo: some ProcessReporting) async {
    self.$processInfo.withLock { $0 = processInfo }
  }

  /// Modify default connection publisher.
  public func setConnectionPublisher(_ publisher: some ConnectionPublisher) async {
    self.$connectionPublisher.withLock { $0 = publisher }
  }

  /// Modify HTTPS decryption PKCS#12 bundle.
  public func setDecryptionSSLPKCS12Bundle(_ sslPKCS12Bundle: NIOSSLPKCS12Bundle?) async {
    guard sslPKCS12Bundle != self.decryptionSSLPKCS12Bundle else {
      return
    }
    guard let sslPKCS12Bundle else {
      self.$decryptionDNSNames.withLock { $0 = [] }
      self.$decryptionSSLPKCS12Bundle.withLock { $0 = nil }
      return
    }

    let decryptionDNSNames: [String] = sslPKCS12Bundle.certificateChain
      .compactMap {
        $0._subjectAlternativeNames()
      }
      .flatMap {
        $0.compactMap {
          guard $0.nameType == .dnsName else {
            return nil
          }
          return String(bytes: $0.contents, encoding: .utf8)
        }
      }

    self.$decryptionDNSNames.withLock { $0 = decryptionDNSNames }
    self.$decryptionSSLPKCS12Bundle.withLock { $0 = sslPKCS12Bundle }
  }

  /// Run analyze services.
  public func run() async throws {
    try await withSpan("run") { _ in
      do {
        guard !isActive else {
          return
        }
        $isActive.withLock { $0 = true }

        try await run0()
      } catch {
        $isActive.withLock { $0 = false }
        throw error
      }
    }
  }

  private func run0() async throws {
    try await withThrowingDiscardingTaskGroup { g in
      g.addTask {
        try await withSpan("HTTP") { _ in
          try await self.startVPNTunnel(protocol: .http, address: self.webProxyListenAddress)
        }
      }

      g.addTask {
        try await withSpan("SOCKS5") { _ in
          try await self.startVPNTunnel(
            protocol: .socks5, address: self.socksProxyListenAddress)
        }
      }
    }
  }

  @available(
    *, noasync,
    message: "This can potentially block the thread and should not be called in an async context",
    renamed: "shutdownGracefully"
  )
  private func syncShutdownGracefully() throws {
    try eventLoopGroup.next().makeFutureWithTask { try await self.shutdownGracefully() }.wait()
  }

  /// Fully shutdown service.
  public func shutdownGracefully() async throws {
    guard self.isActive else {
      return
    }

    $isActive.withLock { $0 = false }

    try await shutdownGracefully0()

    logger.trace("\(processName) fully shutdown complete.")
  }

  private func shutdownGracefully0() async throws {
    // Wait until all channels closed.
    try await withThrowingTaskGroup(of: Void.self) { g in
      for quiescing in self.quiescing {
        g.addTask {
          let promise = self.eventLoopGroup.next().makePromise(of: Void.self)
          quiescing.initiateShutdown(promise: promise)
          // Wait until all child channels closed.
          try await promise.futureResult.get()
        }
      }
      try await g.waitForAll()
    }
  }

  private typealias Flow = (
    inputStream: any Channel, outputStream: any Channel, session: Connection
  )

  /// Start a VPN tunnel for specified protocol.
  /// - Parameters:
  ///   - protocol: The VPN protocol.
  ///   - address: The server for VPN tunnel to bind.
  /// - Returns: Started VPN tunnel and server quiescing helper pair.
  private func startVPNTunnel(protocol: Proxy.`Protocol`, address: SocketAddress) async throws {
    let quiescing = ServerQuiescingHelper(group: eventLoopGroup)

    let channel = try await ServerBootstrap(group: eventLoopGroup)
      .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .serverChannelOption(ChannelOptions.socketOption(.init(rawValue: SO_REUSEPORT)), value: 1)
      .serverChannelInitializer { channel in
        channel.eventLoop.makeCompletedFuture {
          try channel.pipeline.syncOperations.addHandler(
            quiescing.makeServerChannelHandler(channel: channel)
          )
        }
      }
      .childChannelOption(ChannelOptions.tcpOption(.tcp_nodelay), value: 1)
      .bind(to: address) { channel in
        switch `protocol` {
        case .http:
          return channel.configureHTTPListenerPipeline { _, req in
            channel.eventLoop.makeFutureWithTask {
              try await self.initializeFlow(channel, originalRequest: .init(httpRequest: req))
            }
          }
        case .socks5:
          return channel.configureSOCKSListenerPipeline { address in
            channel.eventLoop.makeFutureWithTask {
              try await self.initializeFlow(channel, originalRequest: .init(address: address))
            }
          }
        }
      }

    guard let localAddress = try? channel.channel.localAddress?.asAddress() else {
      fatalError(
        "Address was unable to bind. Please check that the socket was not closed or that the address family was understood."
      )
    }

    self.logger.info(
      "\(processName) \(`protocol`.rawValue.uppercased()) started and listening on \(localAddress)"
    )

    self.$quiescing.withLock {
      $0.append(quiescing)
    }

    _ = Task {
      try await withThrowingDiscardingTaskGroup { g in
        try await channel.executeThenClose { inbound in
          for try await _ in inbound {
            g.addTask {
              await Task.yield()
            }
          }
        }
      }
    }
  }

  private func initializeFlow(_ inputStream: any Channel, originalRequest: Request) async throws
    -> Flow
  {
    try await withSpan("initialize Proxy Flow") { _ in
      let session = Connection()
      do {
        session.originalRequest = originalRequest
        session.currentRequest = originalRequest
        guard let sourceEndpoint = try inputStream.remoteAddress?.asAddress() else {
          throw AnalyzeError.inputStreamEndpointInvalid
        }
        session.establishmentReport = EstablishmentReport(
          duration: .zero,
          attemptStartedAfterInterval: 0,
          previousAttemptCount: 0,
          sourceEndpoint: sourceEndpoint,
          usedProxy: false,
          proxyEndpoint: nil,
          resolutions: []
        )

        await session.publish(using: connectionPublisher)

        try await session.protocolLookup(
          logger: logger,
          outboundMode: outboundMode,
          forwardProtocol: forwardProtocol,
          proc: processInfo,
          resolver: resolver,
          rules: rulesEngine,
          eventLoop: inputStream.eventLoop
        )

        // Create peer channel.
        let forwardProtocol =
          session.forwardingReport?._forwardProtocol as? ForwardProtocol ?? .direct

        let outputStream = try await forwardProtocol.makeConnection(
          logger: logger, connection: session, on: inputStream.eventLoop.next()
        )

        session.state = .active

        await withSpan("establishment-report gen") { _ in
          // Once channel connected, we can request establishment report.
          // Error will be ignored, we don't want connection closed by establishment report
          // generation error.
          let establishmentReport = try? await outputStream.establishmentReport().get()
          if let establishmentReport {
            session.withMutation(keyPath: \.establishmentReport) {
              session.$establishmentReport.withLock {
                assert($0 != nil)

                // `EstablishmentReport.sourceEndpoint` is requested from server channel, but
                // establishment report is requested from client channel, so we need update sourceEndpoint
                // to use original value.
                let usedProxy = $0?.usedProxy ?? false

                $0?.duration = establishmentReport.duration
                $0?.attemptStartedAfterInterval = establishmentReport.attemptStartedAfterInterval
                $0?.previousAttemptCount = establishmentReport.previousAttemptCount
                $0?.proxyEndpoint = usedProxy ? (try? outputStream.remoteAddress?.asAddress()) : nil
                $0?.resolutions = establishmentReport.resolutions
              }
            }
          }
        }

        await session.collectDataTransferMetrics(on: outputStream)

        // Setup HTTP capabilities pipeline
        try await inputStream.eventLoop.submit {
          self.capabilities
            .buildTLS(
              logger: self.logger,
              connection: session,
              decryptionDNSNames: self.decryptionDNSNames,
              decryptionSSLPKCS12Bundle: self.decryptionSSLPKCS12Bundle,
              inputStream: inputStream,
              outputStream: outputStream
            )

          self.capabilities
            .buildHTTP(
              logger: self.logger,
              connection: session,
              inMemoryHTTPCaptureFilters: [],
              onDiskHTTPCaptureFilters: [],
              inputStream: inputStream,
              outputStream: outputStream
            )

          // Exchange server and client data over GlueHandler.
          let (localGlue, peerGlue) = GlueHandler.matchedPair()

          try? inputStream.pipeline.syncOperations.addHandler(localGlue)
          try? outputStream.pipeline.syncOperations.addHandlers(peerGlue)
        }.get()
        return (inputStream, outputStream, session)
      } catch {
        session.duration = .seconds(-session.earliestBeginDate.timeIntervalSinceNow)
        session.state = .failed
        self.logger.error(
          "Connection failure with error: \(error)",
          metadata: session.metadata
        )
        throw error
      }
    }
  }

  deinit {
    logger.trace("\(processName) deinitialized, goodbye!")
    guard isActive else {
      return
    }
    try? syncShutdownGracefully()
  }
}
