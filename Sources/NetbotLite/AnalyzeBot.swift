// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2021 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Atomics
import Dispatch
import Logging
import NEAddressProcessing
import NEHTTP
import NESOCKS
import NIOConcurrencyHelpers
import NIOCore
import NIOExtras
import NIOHTTP1
import NIOHTTPCompression
import NIOSSL
import NetbotLiteData
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
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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
  final public var forwardProtocol: any ForwardProtocolConvertible

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
  final public var processInfo: any ProcessReporting

  /// A publisher publish connection states.
  @LockableTracked(accessors: .get)
  final public var connectionPublisher: any ConnectionPublisher

  /// DNS names that allow HTTPS decryption.
  @LockableTracked(accessors: .get)
  final public var decryptionDNSNames: [String]

  /// `NIOSSLPKCS12Bundle` used to decrypt HTTPS connections.
  @LockableTracked(accessors: .get)
  final public var decryptionSSLPKCS12Bundle: NIOSSLPKCS12Bundle?

  /// True if this `AnalyzeBot` is currently active. Active is defined as the period of time after the `run` and before
  /// `shutdownGracefully` has fired.
  final public var isActive: Bool {
    _isActive.load(ordering: .relaxed)
  }
  private let _isActive = ManagedAtomic<Bool>(false)

  final public var closeFuture: EventLoopFuture<Void>? {
    _closePromise.withLock {
      $0?.futureResult
    }
  }
  private let _closePromise = Mutex<EventLoopPromise<Void>?>(nil)

  private var quiescing: [ServerQuiescingHelper]

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
    self._webProxyListenAddress = .init(webProxyListenAddress)
    self._socksProxyListenAddress = .init(socksProxyListenAddress)
    self._outboundMode = .init(.direct)
    self._forwardProtocol = .init(.direct)
    self._capabilities = .init([])
    self._resolver = .init(DefaultResolver(eventLoop: group.any()))
    self._rulesEngine = .init(DefaultRulesEngine(logger: logger))
    self._processInfo = .init(DefaultProcessReporting())
    self._connectionPublisher = .init(DefaultConnectionPublisher())
    self._decryptionDNSNames = .init([])
    self._decryptionSSLPKCS12Bundle = .init(nil)
    self._quiescing = .init([])
  }

  /// Modify Web and SOCKS proxy settings.
  public func setTunnelNetworkSettings(_ networkSettings: NetworkSettings) async throws {
    guard networkSettings.0 != webProxyListenAddress || networkSettings.1 != socksProxyListenAddress
    else {
      return
    }

    _webProxyListenAddress.withLock { $0 = networkSettings.0 }
    _socksProxyListenAddress.withLock { $0 = networkSettings.1 }

    if isActive {
      try await shutdownGracefully()
      try await run()
    }
  }

  /// Modify outbound mode.
  public func setOutboundMode(_ outboundMode: OutboundMode) async {
    self._outboundMode.withLock { $0 = outboundMode }
  }

  /// Modify global forward protocol.
  public func setForwardProtocol(_ newForwardProtocol: any ForwardProtocolConvertible) async {
    self._forwardProtocol.withLock { $0 = newForwardProtocol }
  }

  /// Modify forwarding rules.
  public func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async {
    self.rulesEngine.setForwardingRules(forwardingRules)
  }

  /// Modify enabled HTTP capabilities.
  public func setEnabledHTTPCapabilities(_ enabledHTTPCapabilities: CapabilityFlags) async {
    self._capabilities.withLock { $0 = enabledHTTPCapabilities }
  }

  /// Modify the DNS resolver.
  public func setResolver(_ resolver: Resolver) async {
    self._resolver.withLock { $0 = resolver }
  }

  /// Modify forwarding rules engine.
  public func setRulesEngine(_ rulesEngine: RulesEngine) async {
    self._rulesEngine.withLock { $0 = rulesEngine }
  }

  /// Modify default process info detector.
  public func setProcessInfo(_ processInfo: ProcessReporting) async {
    self._processInfo.withLock { $0 = processInfo }
  }

  /// Modify default connection publisher.
  public func setConnectionPublisher(_ publisher: ConnectionPublisher) async {
    self._connectionPublisher.withLock { $0 = publisher }
  }

  /// Modify HTTPS decryption PKCS#12 bundle.
  public func setDecryptionSSLPKCS12Bundle(_ sslPKCS12Bundle: NIOSSLPKCS12Bundle?) async {
    guard sslPKCS12Bundle != self.decryptionSSLPKCS12Bundle else {
      return
    }
    guard let sslPKCS12Bundle else {
      self._decryptionDNSNames.withLock { $0 = [] }
      self._decryptionSSLPKCS12Bundle.withLock { $0 = nil }
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

    self._decryptionDNSNames.withLock { $0 = decryptionDNSNames }
    self._decryptionSSLPKCS12Bundle.withLock { $0 = sslPKCS12Bundle }
  }

  /// Run analyze services.
  public func run() async throws {
    Task { try await run0() }
  }

  /// Run analyze services and block IO until closed.
  public func run0() async throws {
    try await withSpan("run") { _ in
      do {
        guard !isActive else {
          return
        }
        _isActive.store(true, ordering: .relaxed)
        _closePromise.withLock { $0 = eventLoopGroup.any().makePromise() }

        #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
          if #available(SwiftStdlib 5.9, *) {
            try await withThrowingDiscardingTaskGroup { g in
              g.addTask {
                try await withSpan("HTTP") { _ in
                  try await self.startVPNTunnel(
                    protocol: .http, address: self.webProxyListenAddress)
                }
              }

              g.addTask {
                try await withSpan("SOCKS5") { _ in
                  try await self.startVPNTunnel(
                    protocol: .socks5, address: self.socksProxyListenAddress)
                }
              }
            }
          } else {
            // Run and wait until all server channels closed.
            try await withThrowingTaskGroup(of: Void.self) { g in
              g.addTask {
                try await withSpan("HTTP") { _ in
                  try await self.startVPNTunnel(
                    protocol: .http, address: self.webProxyListenAddress)
                }
              }

              g.addTask {
                try await withSpan("SOCKS5") { _ in
                  try await self.startVPNTunnel(
                    protocol: .socks5, address: self.socksProxyListenAddress)
                }
              }
              try await g.waitForAll()
            }
          }
        #else
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
        #endif
      } catch {
        _isActive.store(false, ordering: .relaxed)
        _closePromise.withLock { $0?.fail(error) }
        throw error
      }
    }
  }

  @available(
    *, noasync,
    message: "This can potentially block the thread and should not be called in an async context",
    renamed: "shutdownGracefully"
  )
  private func syncShutdownGracefully() throws {
    try eventLoopGroup.any().makeFutureWithTask { try await self.shutdownGracefully() }.wait()
  }

  /// Fully shutdown service.
  public func shutdownGracefully() async throws {
    guard self.isActive else {
      return
    }

    do {
      // Wait until all channels closed.
      try await withThrowingTaskGroup(of: Void.self) { g in
        for quiescing in self.quiescing {
          g.addTask {
            let promise = self.eventLoopGroup.any().makePromise(of: Void.self)
            quiescing.initiateShutdown(promise: promise)
            // Wait until all child channels closed.
            try await promise.futureResult.get()
          }
        }
        try await g.waitForAll()
      }
    } catch {
      _closePromise.withLock { $0?.fail(error) }
      throw error
    }

    _isActive.store(false, ordering: .relaxed)
    _closePromise.withLock { $0?.succeed() }

    logger.trace("\(processName) fully shutdown complete.")
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

    let bootstrap = ServerBootstrap(group: eventLoopGroup)
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

    @inline(__always)
    @Sendable func channelInitializer(_ channel: any Channel) -> EventLoopFuture<
      EventLoopFuture<Flow>
    > {
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

    @inline(__always)
    func postBind(channel: any Channel) {
      guard let localAddress = try? channel.localAddress?.asAddress() else {
        fatalError(
          "Address was unable to bind. Please check that the socket was not closed or that the address family was understood."
        )
      }

      self.logger.info(
        "\(processName) \(`protocol`.rawValue.uppercased()) started and listening on \(localAddress)"
      )

      self._quiescing.withLock {
        $0.append(quiescing)
      }
    }

    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.9, *) {
        let channel = try await bootstrap.bind(
          to: address, childChannelInitializer: channelInitializer)

        postBind(channel: channel.channel)

        try await withThrowingDiscardingTaskGroup { g in
          try await channel.executeThenClose { inbound in
            for try await _ in inbound {
              g.addTask {

              }
            }
          }
        }
      } else {
        let channel = try await bootstrap.childChannelInitializer { channel in
          channelInitializer(channel).flatMap { _ in
            channel.eventLoop.makeSucceededVoidFuture()
          }
        }
        .bind(to: address).get()

        postBind(channel: channel)

        try await channel.closeFuture.get()
      }
    #else
      let channel = try await bootstrap.bind(
        to: address, childChannelInitializer: channelInitializer)

      postBind(channel: channel.channel)

      try await withThrowingDiscardingTaskGroup { g in
        try await channel.executeThenClose { inbound in
          for try await _ in inbound {
            g.addTask {

            }
          }
        }
      }
    #endif
  }

  private func initializeFlow(_ inputStream: any Channel, originalRequest: Request) async throws
    -> Flow
  {
    try await withSpan("initialize Proxy Flow") { _ in
      let session = Connection()
      do {
        session.originalRequest = originalRequest
        guard let sourceEndpoint = try inputStream.remoteAddress?.asAddress() else {
          throw AnalyzeError.inputStreamEndpointInvalid
        }
        session.establishmentReport = EstablishmentReport(
          duration: 0,
          attemptStartedAfterInterval: 0,
          previousAttemptCount: 0,
          sourceEndpoint: sourceEndpoint,
          usedProxy: false,
          proxyEndpoint: nil,
          resolutions: []
        )

        await session.publish(with: connectionPublisher)

        try await session.evalProtocolLookup(
          logger: logger,
          outboundMode: outboundMode,
          forwardProtocol: forwardProtocol,
          proc: processInfo,
          resolver: resolver,
          rules: rulesEngine,
          on: inputStream.eventLoop
        )

        // Create peer channel.
        let forwardProtocol =
          session.forwardingReport?._forwardProtocol as? ForwardProtocol ?? .direct

        let outputStream = try await forwardProtocol.makeConnection(
          logger: logger, connection: session, on: inputStream.eventLoop.any()
        )

        session.state = .active

        await withSpan("establishment-report gen") { _ in
          // Once channel connected, we can request establishment report.
          // Error will be ignored, we don't want connection closed by establishment report
          // generation error.
          let establishmentReport = try? await outputStream.establishmentReport().get()
          if let establishmentReport {
            session._establishmentReport.withLock {
              assert($0 != nil)

              // `EstablishmentReport.sourceEndpoint` is requested from server channel, but
              // establishment report is requested from client channel, so we need update sourceEndpoint
              // to use original value.
              let usedProxy = $0?.usedProxy ?? false

              $0?._duration = establishmentReport._duration
              $0?.attemptStartedAfterInterval = establishmentReport.attemptStartedAfterInterval
              $0?.previousAttemptCount = establishmentReport.previousAttemptCount
              $0?.proxyEndpoint = usedProxy ? (try? outputStream.remoteAddress?.asAddress()) : nil
              $0?.resolutions = establishmentReport.resolutions
            }
          }
        }

        await session.collectDataTransferMetrics(on: outputStream)

        // Setup HTTP capabilities pipeline
        try await inputStream.eventLoop.submit {
          // Because the capabilities may change, we need temporary variables to maintain
          // capabilities consistency.
          let capabilities = self.capabilities
          let decryptionDNSNames = self.decryptionDNSNames
          let decryptionSSLPKCS12Bundle = self.decryptionSSLPKCS12Bundle

          inputStream.eventLoop.assertInEventLoop()

          try? inputStream.pipeline.syncOperations.addHandler(
            Recognizer.Handler<Recognizer.TLS> { result in
              var mayBeTLS = false
              if case .identified(let proto) = result {
                mayBeTLS = proto == "TLS"
              }
              session.tls = mayBeTLS

              // To continue the TLS decryption pipeline setup, we need to confirm that the
              // current session contains a clear host name and is transmitted through TLS.
              // At the same time, we must ensure that https decryption has been enabled and
              // the relevant certificates used for decryption are valid.
              guard mayBeTLS,
                capabilities.contains(.httpsDecryption),
                let decryptionSSLPKCS12Bundle,
                let host = session.originalRequest?.host(percentEncoded: false)
              else {
                return inputStream.eventLoop.makeSucceededVoidFuture()
              }

              // Check whether the hostname should support TLS decryption.
              let decryptionRequired = decryptionDNSNames.contains {
                guard $0.hasPrefix("*.") else { return host == $0 }
                return host.hasSuffix(String($0.dropFirst()))
              }
              guard decryptionRequired else {
                return inputStream.eventLoop.makeSucceededVoidFuture()
              }

              return EventLoopFuture.andAllComplete(
                [
                  SSLContextCache.shared.sslContext(
                    configuration: .makeServerConfiguration(
                      certificateChain: decryptionSSLPKCS12Bundle.certificateChain.map {
                        .certificate($0)
                      },
                      privateKey: .privateKey(decryptionSSLPKCS12Bundle.privateKey)
                    ),
                    eventLoop: inputStream.eventLoop,
                    logger: self.logger
                  )
                  .flatMap { sslContext in
                    inputStream.eventLoop.makeCompletedFuture {
                      let position = try inputStream.pipeline.syncOperations.context(
                        name: Recognizer.TLS.name
                      ).handler
                      try inputStream.pipeline.syncOperations.addHandler(
                        NIOSSLServerHandler(context: sslContext), position: .after(position)
                      )
                    }
                  },

                  // Because we have decrypted HTTPS stream, so we need set up client channel to encode decrypted
                  // plain HTTP request to HTTPS request.
                  SSLContextCache.shared.sslContext(
                    configuration: .makeClientConfiguration(),
                    eventLoop: outputStream.eventLoop,
                    logger: self.logger
                  )
                  .flatMap { sslContext in
                    outputStream.eventLoop.makeCompletedFuture {
                      let handler = try NIOSSLClientHandler(
                        context: sslContext, serverHostname: host)
                      try outputStream.pipeline.syncOperations.addHandler(handler)
                    }
                  },
                ], on: inputStream.eventLoop)
            },
            name: Recognizer.TLS.name
          )

          try? inputStream.pipeline.syncOperations.addHandler(
            Recognizer.Handler<Recognizer.HTTP> { result in
              var mayBeHTTP = false
              if case .identified(let proto) = result {
                mayBeHTTP = proto == "HTTP"
              }

              // Try to setup TLS decryption if current connection is over TLS and enabled
              // capabilities contains httpsDecryption.
              guard mayBeHTTP,
                capabilities.contains(.httpCapture) || capabilities.contains(.rewrite)
              else { return inputStream.eventLoop.makeSucceededVoidFuture() }

              return EventLoopFuture.andAllComplete(
                [
                  inputStream.eventLoop.makeCompletedFuture {
                    let position = try inputStream.pipeline.syncOperations.context(
                      name: Recognizer.HTTP.name
                    ).handler
                    try inputStream.pipeline.syncOperations.addHandlers(
                      [
                        HTTPResponseEncoder(),
                        ByteToMessageHandler(HTTPRequestDecoder()),
                        HTTPResponseCompressor(),
                        __CapabilitiesProcessingHandler<HTTPRequestHead>(
                          application: self,
                          connection: session,
                          enabledHTTPCapabilities: capabilities
                        ),
                      ], position: .after(position))
                  },

                  outputStream.eventLoop.makeCompletedFuture {
                    try outputStream.pipeline.syncOperations.addHandlers([
                      HTTPRequestEncoder(),
                      ByteToMessageHandler(HTTPResponseDecoder()),
                      NIOHTTPResponseDecompressor(limit: .none),
                      __CapabilitiesProcessingHandler<HTTPResponseHead>(
                        application: self,
                        connection: session,
                        enabledHTTPCapabilities: capabilities
                      ),
                    ])
                  },
                ], on: inputStream.eventLoop)
            },
            name: Recognizer.HTTP.name
          )

          // Exchange server and client data over GlueHandler.
          let (localGlue, peerGlue) = GlueHandler.matchedPair()

          try? inputStream.pipeline.syncOperations.addHandler(localGlue)
          try? outputStream.pipeline.syncOperations.addHandlers(peerGlue)
        }.get()
        return (inputStream, outputStream, session)
      } catch {
        session._duration = -session.earliestBeginDate.timeIntervalSinceNow
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
