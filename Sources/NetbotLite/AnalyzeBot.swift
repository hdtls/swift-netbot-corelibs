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

import Logging
import NEAddressProcessing
import NEHTTP
import NESOCKS
import NIOCore
import NIOExtras
import NIOHTTP1
import NIOSSL
import NetbotDNS
import NetbotLiteData
import NetbotNIO
import ServiceLifecycle
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
@Lockable final public class AnalyzeBot: Sendable {

  public typealias NetworkSettings = (Address, Address)

  /// Address of web proxy (HTTP/HTTPS) server will bind if present.
  @LockableTracked(accessors: .get)
  public var webProxyListenAddress: Address = .hostPort(host: "127.0.0.1", port: 6152)

  /// Address of SOCKS proxy server will bind if present.
  @LockableTracked(accessors: .get)
  public var socksProxyListenAddress: Address = .hostPort(host: "127.0.0.1", port: 1080)

  /// The outbound mode control how requests will be process.
  @LockableTracked(accessors: .get)
  public var outboundMode: OutboundMode = .direct

  /// Forward protocol used in global proxy outbound mode.
  @LockableTracked(accessors: .get)
  public var forwardProtocol: any ForwardProtocolConvertible = .direct

  /// The rules used to make outbound stream.
  public var forwardingRules: [any ForwardingRuleConvertible] {
    self.rulesEngine.forwardingRules
  }

  /// A set of enabled capabilities, default is empty.
  @LockableTracked(accessors: .get)
  public var capabilities: CapabilityFlags = []

  /// The dns resolver.
  @LockableTracked(accessors: .get)
  public var dnsResolver: any DNSResolver = DefaultDNSResolver()

  /// The RulesEngine evaluates the Rules.
  @LockableTracked(accessors: .get)
  public var rulesEngine: any RulesEngine

  /// A service help detect the process that the current connection is created.
  @LockableTracked(accessors: .get)
  public var processResolver: any ProcessResolver = DefaultProcessResolver()

  /// A tracker broadcast all VPN task states.
  @LockableTracked(accessors: .get)
  public var coreVPNTaskTracker: any CoreVPNTaskTracker = DefaultVPNTaskTracker()

  /// DNS names that allow HTTPS decryption.
  @LockableTracked(accessors: .get)
  public var decryptionDNSNames: [String] = []

  /// `NIOSSLPKCS12Bundle` used to decrypt HTTPS connections.
  @LockableTracked(accessors: .get)
  public var decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle? = nil

  private let group: any EventLoopGroup

  /// Initialize an new instance of `AnalyzeBot`.
  public init(group: any EventLoopGroup = .default) {
    self.group = group
    self.$rulesEngine = .init(DefaultRulesEngine())
  }

  /// Set current Web and SOCKS proxy settings to new `networkSettings`.
  public func setTunnelNetworkSettings(_ networkSettings: NetworkSettings) async throws {
    guard networkSettings.0 != webProxyListenAddress || networkSettings.1 != socksProxyListenAddress
    else {
      return
    }

    $webProxyListenAddress.withLock { $0 = networkSettings.0 }
    $socksProxyListenAddress.withLock { $0 = networkSettings.1 }
  }

  /// Set current outbound mode to new `outboundMode`.
  public func setOutboundMode(_ outboundMode: OutboundMode) async {
    self.$outboundMode.withLock { $0 = outboundMode }
  }

  /// Set current global forward protocol to new `forwardProtocol`.
  public func setForwardProtocol(_ forwardProtocol: any ForwardProtocolConvertible) async {
    self.$forwardProtocol.withLock { $0 = forwardProtocol }
  }

  /// Set current forwarding rules to new `forwardingRules`.
  public func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async {
    self.rulesEngine.setForwardingRules(forwardingRules)
  }

  /// Set current enabled HTTP capabilities to new `enabledHTTPCapabilities`.
  public func setEnabledHTTPCapabilities(_ enabledHTTPCapabilities: CapabilityFlags) async {
    self.$capabilities.withLock { $0 = enabledHTTPCapabilities }
  }

  /// Set current the DNS resolver to new `resolver`.
  public func setDNSResolver(_ resolver: some DNSResolver) async {
    self.$dnsResolver.withLock { $0 = resolver }
  }

  /// Set current forwarding rules engine to new `rulesEngine`.
  public func setRulesEngine(_ rulesEngine: some RulesEngine) async {
    self.$rulesEngine.withLock { $0 = rulesEngine }
  }

  /// Set current default process resolver to new `resolver`.
  public func setProcessResolver(_ resolver: some ProcessResolver) async {
    self.$processResolver.withLock { $0 = resolver }
  }

  /// Set current VPN task tracker to new `tracker`.
  public func setCoreVPNTaskTracker(_ tracker: some CoreVPNTaskTracker) async {
    self.$coreVPNTaskTracker.withLock { $0 = tracker }
  }

  /// Set current HTTPS decryption PKCS#12 bundle to new `sslPKCS12Bundle`.
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
      try await withThrowingDiscardingTaskGroup { g in
        g.addTask(name: "HTTP proxy") {
          try await withSpan("HTTP proxy") { _ in
            try await self.startVPNTunnel(
              name: "HTTP proxy",
              address: self.webProxyListenAddress,
              childChannelInitializer: { channel in
                return channel.configureHTTPListenerPipeline { _, req in
                  channel.eventLoop.makeFutureWithTask {
                    try await self.initializeFlow(channel, originalRequest: .init(httpRequest: req))
                  }
                }
              }
            ) { inbound in
              try await withThrowingDiscardingTaskGroup { _ in
                for try await _ in inbound {
                }
              }
            }
          }
        }

        g.addTask(name: "SOCKSv5 proxy") {
          try await withSpan("SOCKSv5 proxy") { _ in
            try await self.startVPNTunnel(
              name: "SOCKSv5 proxy",
              address: self.socksProxyListenAddress,
              childChannelInitializer: { channel in
                return channel.configureSOCKSListenerPipeline { address in
                  channel.eventLoop.makeFutureWithTask {
                    try await self.initializeFlow(channel, originalRequest: .init(address: address))
                  }
                }
              }
            ) { inbound in
              try await withThrowingDiscardingTaskGroup { _ in
                for try await _ in inbound {
                }
              }
            }
          }
        }
      }
    }
  }

  private typealias Flow = (
    inputStream: any Channel, outputStream: any Channel, session: Connection
  )

  private func startVPNTunnel<Child: Sendable>(
    name: String,
    address: Address,
    childChannelInitializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Child>,
    _ body: (NIOAsyncChannelInboundStream<Child>) async throws -> Void
  ) async throws {
    let serverQuiescingHelper = ServerQuiescingHelper(group: group)

    let serverChannel = try await ServerBootstrap(group: group)
      .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .serverChannelOption(ChannelOptions.socketOption(.so_reuseport), value: 1)
      .serverChannelInitializer { channel in
        channel.eventLoop.makeCompletedFuture {
          try channel.pipeline.syncOperations.addHandler(
            serverQuiescingHelper.makeServerChannelHandler(channel: channel)
          )
        }
      }
      .childChannelOption(ChannelOptions.tcpOption(.tcp_nodelay), value: 1)
      .bind(to: address.asAddress(), childChannelInitializer: childChannelInitializer)

    try await withTaskCancellationHandler {
      try await withGracefulShutdownHandler {
        if Task.isCancelled {
          // The cancellation/shutdown handler will have closed the socket. Just await the closeFuture here.
          try? await serverChannel.channel.closeFuture.get()
          return
        }

        guard let address = try? serverChannel.channel.localAddress?.asAddress() else {
          fatalError(
            "Address was unable to bind. Please check that the socket was not closed or that the address family was understood."
          )
        }

        Logger.current.info("\(name) started and listen on \(address)")

        try await serverChannel.executeThenClose { inbound in
          try await body(inbound)
        }
      } onGracefulShutdown: {
        serverQuiescingHelper.initiateShutdown(promise: nil)
      }
    } onCancel: {
      serverChannel.channel.close(promise: nil)
    }
  }

  private func initializeFlow(_ inputStream: any Channel, originalRequest: Request) async throws
    -> Flow
  {
    try await withSpan("initialize Proxy Flow") { span in
      let session = Connection()
      session.originalRequest = originalRequest
      session.currentRequest = originalRequest
      return try await withLogger(mergingMetadata: session.metadata) { logger in
        do {
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

          span.updateAttributes { attributes in
            attributes["id"] = "\(session.taskIdentifier)"
            attributes["establishment.source"] = "\(sourceEndpoint)"
          }

          // Publish session changes using connection publisher.
          await session.publish(using: coreVPNTaskTracker)

          // Update transport metrics.
          await session.transportMetrics(on: nil)

          try await session.protocolLookup(
            outboundMode: outboundMode,
            forwardProtocol: forwardProtocol,
            processResolver: processResolver,
            dnsResolver: dnsResolver,
            rules: rulesEngine,
            eventLoop: inputStream.eventLoop
          )

          // Create peer channel.
          let outputStream = try await session.forwardingReport
            .asForwardProtocol()
            .makeConnection(context: session, on: group.next())

          session.state = .active

          await session.establishmentMetrics(on: outputStream)

          // Update transport metrics.
          await session.transportMetrics(on: outputStream)

          // Setup HTTP capabilities pipeline
          try await inputStream.eventLoop.submit {
            self.capabilities
              .buildTLS(
                connection: session,
                decryptionDNSNames: self.decryptionDNSNames,
                decryptionSSLPKCS12Bundle: self.decryptionSSLPKCS12Bundle,
                inputStream: inputStream,
                outputStream: outputStream
              )

            self.capabilities
              .buildHTTP(
                connection: session,
                inMemoryHTTPCaptureFilters: [],
                onDiskHTTPCaptureFilters: [],
                inputStream: inputStream,
                outputStream: outputStream
              )

            outputStream.eventLoop.execute {
              let connectionClose = ConnectionClose(connection: session)
              try? outputStream.pipeline.syncOperations.addHandler(connectionClose)
            }

            // Exchange server and client data over GlueHandler.
            let (localGlue, peerGlue) = GlueHandler.matchedPair()

            try? inputStream.pipeline.syncOperations.addHandler(localGlue)

            outputStream.eventLoop.execute {
              try? outputStream.pipeline.syncOperations.addHandlers(peerGlue)
            }
          }.get()

          span.setStatus(.init(code: .ok))
          return (inputStream, outputStream, session)
        } catch {
          session.duration = .seconds(-session.earliestBeginDate.timeIntervalSinceNow)
          session.state = .failed
          logger.error(
            "Connection failure with error: \(error)",
            metadata: session.metadata
          )
          throw error
        }
      }
    }
  }

  deinit {
    Logger.current.trace("AnalyzeBot deinitialized, goodbye!")
  }
}
