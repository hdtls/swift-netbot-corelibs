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

#if canImport(Network)
  import X509
  import Network
#else
  import NIOSSL
#endif

#if canImport(Network)
  @available(SwiftStdlib 5.3, *)
  enum TLSVersion: Sendable {
    case tlsv1
    case tlsv11
    case tlsv12
    case tlsv13

    internal var supportedTLSVersion: tls_protocol_version_t {
      switch self {
      case .tlsv1:
        if #available(macOS 12.0, *) {
          return .TLSv12
        } else {
          return .TLSv10
        }
      case .tlsv11:
        if #available(macOS 12.0, *) {
          return .TLSv12
        } else {
          return .TLSv11
        }
      case .tlsv12:
        return .TLSv12
      case .tlsv13:
        return .TLSv13
      }
    }
  }

  /// Certificate verification modes.
  @available(SwiftStdlib 5.3, *)
  enum CertificateVerification: Sendable {
    /// All certificate verification disabled.
    case none

    /// Certificates will be validated against the trust store, but will not
    /// be checked to see if they are valid for the given hostname.
    case noHostnameVerification

    /// Certificates will be validated against the trust store and checked
    /// against the hostname of the service we are contacting.
    case fullVerification
  }

  /// Places NIOSSL can obtain a trust store from.
  @available(SwiftStdlib 5.3, *)
  enum NIOSSLTrustRoots: Hashable, Sendable {
    /// Path to either a file of CA certificates in PEM format, or a directory containing CA certificates in PEM format.
    ///
    /// If a path to a file is provided, the file can contain several CA certificates identified by
    ///
    ///     -----BEGIN CERTIFICATE-----
    ///     ... (CA certificate in base64 encoding) ...
    ///     -----END CERTIFICATE-----
    ///
    /// sequences. Before, between, and after the certificates, text is allowed which can be used e.g.
    /// for descriptions of the certificates.
    ///
    /// If a path to a directory is provided, the files each contain one CA certificate in PEM format.
    case file(String)

    /// A list of certificates.
    case certificates([Certificate])

    /// The system default root of trust.
    case `default`

    internal init(from trustRoots: NIOSSLAdditionalTrustRoots) {
      switch trustRoots {
      case .file(let path):
        self = .file(path)
      case .certificates(let certs):
        self = .certificates(certs)
      }
    }
  }

  /// Places NIOSSL can obtain additional trust roots from.
  @available(SwiftStdlib 5.3, *)
  enum NIOSSLAdditionalTrustRoots: Hashable, Sendable {
    /// See ``SSLTrustRoots/file(_:)``
    case file(String)

    /// See ``SSLTrustRoots/certificates(_:)``
    case certificates([Certificate])
  }

  @available(SwiftStdlib 5.3, *)
  struct TLSConfiguration: Sendable {

    static let clientDefault = TLSConfiguration.makeClientConfiguration()

    /// The minimum TLS version to allow in negotiation. Defaults to ``TLSVersion/tlsv1``.
    var minimumTLSVersion = TLSVersion.tlsv1

    /// The maximum TLS version to allow in negotiation. If `nil`, there is no upper limit. Defaults to `nil`.
    var maximumTLSVersion: TLSVersion?

    /// Whether to verify remote certificates.
    var certificateVerification: CertificateVerification

    /// The trust roots to use to validate certificates. This only needs to be provided if you intend to validate
    /// certificates.
    ///
    /// - NOTE: If certificate validation is enabled and ``trustRoots`` is `nil` then the system default root of
    /// trust is used (as if ``trustRoots`` had been explicitly set to ``SSLTrustRoots/default``).
    ///
    /// - NOTE: If a directory path is used here to load a directory of certificates into a configuration, then the
    ///         certificates in this directory must be formatted by `c_rehash` to create the rehash file format of `HHHHHHHH.D` with a symlink.
    var trustRoots: NIOSSLTrustRoots?

    /// Additional trust roots to use to validate certificates, used in addition to ``trustRoots``.
    var additionalTrustRoots: [NIOSSLAdditionalTrustRoots]

    /// The application protocols to use in the connection. Should be an ordered list of ASCII
    /// strings representing the ALPN identifiers of the protocols to negotiate. For clients,
    /// the protocols will be offered in the order given. For servers, the protocols will be matched
    /// against the client's offered protocols in order.
    var applicationProtocols: [String]

    private init(
      minimumTLSVersion: TLSVersion, maximumTLSVersion: TLSVersion?,
      certificateVerification: CertificateVerification, trustRoots: NIOSSLTrustRoots?,
      additionalTrustRoots: [NIOSSLAdditionalTrustRoots], applicationProtocols: [String]
    ) {
      self.minimumTLSVersion = minimumTLSVersion
      self.maximumTLSVersion = maximumTLSVersion
      self.certificateVerification = certificateVerification
      self.trustRoots = trustRoots
      self.additionalTrustRoots = additionalTrustRoots
      self.applicationProtocols = applicationProtocols
    }

    /// Creates a TLS configuration for use with client-side contexts.
    ///
    /// For customising fields, modify the returned TLSConfiguration object.
    static func makeClientConfiguration() -> TLSConfiguration {
      TLSConfiguration(
        minimumTLSVersion: .tlsv1,
        maximumTLSVersion: nil,
        certificateVerification: .fullVerification,
        trustRoots: .default,
        additionalTrustRoots: [],
        applicationProtocols: []
      )
    }
  }
#else
  typealias TLSVersion = NIOSSL.TLSVersion
  typealias CertificateVerification = NIOSSL.CertificateVerification
#endif
