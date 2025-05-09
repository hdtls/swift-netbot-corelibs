//
// See LICENSE.txt for license information
//

import Dispatch
import Logging
import NIOCore
import NIOSSL
import SwiftASN1
import X509
import _ResourceProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Network) && ENABLE_NIO_TRANSPORT_SERVICES
  import Network
  import NIOTransportServices
  import Security
#else
  import Anlzr
#endif

private let offlineQueue = DispatchQueue(label: "com.tenbits.AnalyzerBot.tls.offline.queue")

/// A TLS provider to bootstrap TLS-enabled connections with `NIOClientTCPBootstrap`.
struct NEClientTLSProvider<Bootstrap: NIOClientTCPBootstrapProtocol>: NIOClientTLSProvider {
  typealias Bootstrap = Bootstrap

  #if canImport(Network) && ENABLE_NIO_TRANSPORT_SERVICES
    private let tlsOptions = NWProtocolTLS.Options()
  #else
    let context: NIOSSLContext
    let serverHostname: String?
    /// See ``NIOSSLCustomVerificationCallback`` for more documentation
    let customVerificationCallback:
      (@Sendable ([NIOSSLCertificate], EventLoopPromise<NIOSSLVerificationResult>) -> Void)?

    /// Construct the TLS provider with the necessary configuration.
    ///
    /// - parameters:
    ///     - context: The ``NIOSSLContext`` to use with the connection.
    ///     - serverHostname: The hostname of the server we're trying to connect to, if known. This will be used in the SNI extension,
    ///         and used to validate the server certificate.
    ///     - customVerificationCallback: A callback to use that will override NIOSSL's normal verification logic. See ``NIOSSLCustomVerificationCallback`` for complete documentation.
    ///
    ///         If set, this callback is provided the certificates presented by the peer. NIOSSL will not have pre-processed them. The callback will not be used if the
    ///         ``TLSConfiguration`` that was used to construct the ``NIOSSLContext`` has ``TLSConfiguration/certificateVerification`` set to ``CertificateVerification/none``.
    @preconcurrency
    internal init(
      context: NIOSSLContext,
      serverHostname: String?,
      customVerificationCallback: (
        @Sendable ([NIOSSLCertificate], EventLoopPromise<NIOSSLVerificationResult>) -> Void
      )? = nil
    ) throws {
      try serverHostname.map {
        try $0.validateSNIServerName()
      }
      self.context = context
      self.serverHostname = serverHostname
      self.customVerificationCallback = customVerificationCallback
    }
  #endif

  init(options: TLSConfiguration, sni: String? = nil) throws {
    var serverNameIndicator: String?
    if let sni, !sni.isEmpty, sni.isIPAddress() {
      serverNameIndicator = sni
    }
    #if canImport(Network) && ENABLE_NIO_TRANSPORT_SERVICES
      serverNameIndicator?.withCString { serverNameIndicatorOverride in
        sec_protocol_options_set_tls_server_name(
          tlsOptions.securityProtocolOptions, serverNameIndicatorOverride)
      }

      sec_protocol_options_set_min_tls_protocol_version(
        tlsOptions.securityProtocolOptions, options.minimumTLSVersion.supportedTLSVersion
      )

      if let maximumTLSVersion = options.maximumTLSVersion {
        sec_protocol_options_set_max_tls_protocol_version(
          tlsOptions.securityProtocolOptions, maximumTLSVersion.supportedTLSVersion
        )
      }

      for applicationProtocol in options.applicationProtocols {
        applicationProtocol.withCString { buffer in
          sec_protocol_options_add_tls_application_protocol(
            tlsOptions.securityProtocolOptions, buffer
          )
        }
      }

      // trust roots
      var secTrustRoots: [SecCertificate]?
      switch options.trustRoots {
      case .some(.certificates(let certificates)):
        secTrustRoots = try certificates.compactMap { try $0._base }

      case .some(.file(let file)):
        let pemString = try String(contentsOfFile: file, encoding: .utf8)
        let certificates = [try Certificate(pemDocument: .init(pemString: pemString))]
        secTrustRoots = try certificates.compactMap { try $0._base }
      case .some(.default), .none:
        break
      }

      precondition(
        options.certificateVerification != .noHostnameVerification,
        "TLSConfiguration.certificateVerification = .noHostnameVerification is not supported."
      )

      if options.certificateVerification != .fullVerification || options.trustRoots != nil {
        // add verify block to control certificate verification
        sec_protocol_options_set_verify_block(
          tlsOptions.securityProtocolOptions,
          { _, secTrust, completion in
            guard options.certificateVerification != .none else {
              completion(true)
              return
            }

            let trust = sec_trust_copy_ref(secTrust).takeRetainedValue()
            if let trustRootCertificates = secTrustRoots {
              SecTrustSetAnchorCertificates(trust, trustRootCertificates as CFArray)
            }
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
              dispatchPrecondition(condition: .onQueue(offlineQueue))
              SecTrustEvaluateAsyncWithError(trust, offlineQueue) { _, result, error in
                if let error = error {
                  print("Trust failed: \(error.localizedDescription)")
                }
                completion(result)
              }
            } else {
              SecTrustEvaluateAsync(trust, offlineQueue) { _, result in
                switch result {
                case .proceed, .unspecified:
                  completion(true)
                default:
                  completion(false)
                }
              }
            }
          },
          offlineQueue
        )
      }
    #else
      var configuration = NIOSSL.TLSConfiguration.clientDefault
      configuration.minimumTLSVersion = options.minimumTLSVersion
      configuration.maximumTLSVersion = options.maximumTLSVersion
      configuration.certificateVerification = options.certificateVerification
      configuration.trustRoots = options.trustRoots.map {
        switch $0 {
        case .file(let file):
          return .file(file)
        case .certificates(let certificates):
          return .certificates(certificates.compactMap { try? $0._base })
        case .default:
          return .default
        }
      }
      configuration.additionalTrustRoots = options.additionalTrustRoots.map {
        switch $0 {
        case .file(let file):
          return .file(file)
        case .certificates(let certificates):
          return .certificates(certificates.compactMap { try? $0._base })
        }
      }
      configuration.applicationProtocols = options.applicationProtocols

      let sslContext = try SSLContextCache.shared.syncSSLContext(
        configuration: configuration, logger: Logger(label: "")
      )

      try self.init(context: sslContext, serverHostname: serverNameIndicator)
    #endif
  }

  /// Enable TLS on the bootstrap. This is not a function you will typically call as a user, it is called by
  /// `NIOClientTCPBootstrap`.
  func enableTLS(_ bootstrap: Bootstrap) -> Bootstrap {
    #if canImport(Network) && ENABLE_NIO_TRANSPORT_SERVICES
      if let bootstrap = bootstrap as? NIOTSConnectionBootstrap {
        return bootstrap.tlsOptions(self.tlsOptions) as! Bootstrap
      } else {
        return bootstrap
      }
    #else
      // NIOSSLClientHandler.init only throws because of `malloc` error and invalid SNI hostnames. We want to crash
      // on malloc error and we pre-checked the SNI hostname in `init` so that should be impossible here.
      bootstrap.protocolHandlers {
        [
          try! NIOSSLClientHandler(
            context: self.context,
            serverHostname: self.serverHostname,
            customVerificationCallback: customVerificationCallback,
            configuration: .init()
          )
        ]
      }
    #endif
  }
}

extension Certificate {
  #if canImport(Network) && ENABLE_NIO_TRANSPORT_SERVICES
    fileprivate var _base: SecCertificate? {
      get throws {
        var serializer = DER.Serializer()
        try serializer.serialize(self)
        return SecCertificateCreateWithData(nil, Data(serializer.serializedBytes) as CFData)
      }
    }
  #else
    fileprivate var _base: NIOSSLCertificate {
      get throws {
        var serializer = DER.Serializer()
        try serializer.serialize(self)
        return try NIOSSLCertificate(bytes: serializer.serializedBytes, format: .der)
      }
    }
  #endif
}

extension String {
  fileprivate func validateSNIServerName() throws {
    guard !self.isIPAddress() else {
      throw NIOSSLExtraError.cannotUseIPAddressInSNI
    }

    // no 0 bytes
    guard !self.utf8.contains(0) else {
      throw NIOSSLExtraError.invalidSNIHostname
    }

    guard (1...255).contains(self.utf8.count) else {
      throw NIOSSLExtraError.invalidSNIHostname
    }
  }
}
