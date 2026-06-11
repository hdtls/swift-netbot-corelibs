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

import CryptoExtras
import Logging
import NIOCore
import NIOSSL
import SwiftASN1
import X509

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(Security)
  import Security
#endif

/// `CertbotError` is the error type returned by Certbot. It encompasses a few different
/// types of errors, each with their own associated reasons.
@available(SwiftStdlib 6.0, *)
public enum CertbotError: Error {

  /// The underlying reason the `.certificateLoadFailed` error occurred.
  public enum LoadFailureReason: Sendable {
    /// Input file is nil
    case inputFileNil

    /// Input file can't be read.
    case inputFileReadFailed

    /// Input bundle load success but there is no valid certificates in this bundle.
    case noValidCertificate
  }

  /// Certification load failed.
  case certificateLoadFailed(reason: LoadFailureReason)

  /// The underlying reason the `.certificateTrustFailed` error occurred.
  public enum TrustFailureReason: Sendable {
    case system(code: Int, reason: String?)
    case iii
  }

  /// Certification trust failed.
  case certificateTrustFailed(reason: TrustFailureReason)

  /// Operation unsupported.
  case operationUnsupported
}

/// An certificate managment object.
///
/// This object allow user to load, generate, install and trust certificates.
@available(SwiftStdlib 6.0, *)
#if canImport(Darwin) || swift(>=6.3)
  @Observable
#endif
@MainActor final public class Certbot: @unchecked Sendable {

  private struct Backing: Sendable {

    let representation: Certificate

    #if canImport(Security)
      var certificate: SecCertificate? {
        get throws {
          var serializer = DER.Serializer()
          try serializer.serialize(representation)
          return SecCertificateCreateWithData(nil, Data(serializer.serializedBytes) as CFData)
        }
      }
    #endif

    let commonName: String

    let passphrase: String?

    let base64EncodedP12String: String
  }

  /// Strategy describe how to make passphrase for PKCS#12 bundle.
  public enum PassphraseStrategy: Sendable {
    /// Automatically generate passphrase.
    case auto

    /// Use custom provided passphrase.
    case custom(String)
  }

  private var backing: Backing?

  /// Returns the common name of the loaded certificate.
  public var commonName: String? {
    backing?.commonName
  }

  /// Returns the date before which the loaded certificate is not valid.
  public var notValidBefore: Date? {
    backing?.representation.notValidBefore
  }

  /// Returns the date after which the loaded certificate is not valid.
  public var notValidAfter: Date? {
    backing?.representation.notValidAfter
  }

  /// Returns a boolean value determine whether the loaded certificate is expired.
  public var isExpired: Bool {
    guard let notValidBefore, let notValidAfter else {
      return true
    }
    let now = Date.now
    return now > notValidAfter || now < notValidBefore
  }

  /// Returns base64 encoded PKCS#12 bundle string of the loaded certificate.
  public var base64EncodedP12String: String {
    backing?.base64EncodedP12String ?? ""
  }

  /// Returns the passphrase for  the loaded PKCS#12 bundle.
  public var passphrase: String {
    backing?.passphrase ?? ""
  }

  /// Returns a boolean value determine whether the loaded certificate is trusted by user or not.
  public var isTrusted: Bool {
    _isTrusted
  }
  private var _isTrusted: Bool = false

  #if canImport(Security)
    /// Returns the loaded certificate object for use in Security framework.
    public var certificate: SecCertificate? {
      try? backing?.certificate
    }
  #endif

  /// Logger for certbot.
  nonisolated let logger = Logger(label: "Certbot")

  #if canImport(Darwin) || swift(>=6.3)
    @ObservationIgnored private var generatingTask: Task<Backing, any Error>?
  #else
    private var generatingTask: Task<Backing, any Error>?
  #endif

  /// Create a new instance of `Certbot`.
  nonisolated public init() {
  }

  #if swift(>=6.2)
    /// Load certificate from base64 encoded PKCS#12 bundle string.
    @concurrent public func loadFromBase64EncodedP12String(
      _ base64String: String?, passphrase: String?
    )
      async throws
    {
      try await _loadFromBase64EncodedP12String(base64String, passphrase: passphrase)
    }
  #else
    /// Load certificate from base64 encoded PKCS#12 bundle string.
    nonisolated public func loadFromBase64EncodedP12String(
      _ base64String: String?, passphrase: String?
    )
      async throws
    {
      try await _loadFromBase64EncodedP12String(base64String, passphrase: passphrase)
    }
  #endif

  nonisolated private func _loadFromBase64EncodedP12String(
    _ base64String: String?, passphrase: String?
  )
    async throws
  {
    guard let base64String else {
      self.logger.error("Load PKCS#12 bundle failed data corrupted (nil)")
      throw CertbotError.certificateLoadFailed(reason: .inputFileNil)
    }

    guard let buffer = Data(base64Encoded: base64String), !buffer.isEmpty else {
      self.logger.trace("Load PKCS#12 bundle failed with error: data corrupted (\(base64String)")
      throw CertbotError.certificateLoadFailed(reason: .inputFileReadFailed)
    }

    let backing = try await self.loadFromP12Data(buffer, passphrase: passphrase)
    let isTrusted = try self.trustEvaluate(certificate: backing.representation)

    await MainActor.run {
      self.backing = backing
      self._isTrusted = isTrusted
    }
  }

  #if swift(>=6.2)
    /// Load certificate from url where PKCS#12 bundle saved.
    @concurrent public func loadFromP12File(at url: URL, passphrase: String?) async throws {
      try await _loadFromP12File(at: url, passphrase: passphrase)
    }
  #else
    /// Load certificate from url where PKCS#12 bundle saved.
    nonisolated public func loadFromP12File(at url: URL, passphrase: String?) async throws {
      try await _loadFromP12File(at: url, passphrase: passphrase)
    }
  #endif

  nonisolated private func _loadFromP12File(at url: URL, passphrase: String?) async throws {
    let data = try Data(contentsOf: url)
    let backing = try await self.loadFromP12Data(data, passphrase: passphrase)
    let isTrusted = try self.trustEvaluate(certificate: backing.representation)

    await MainActor.run {
      self.backing = backing
      self._isTrusted = isTrusted
    }
  }

  /// Load certificate from PKCS#12 bundle data.
  nonisolated private func loadFromP12Data(_ pkcs12Data: Data, passphrase: String?) async throws
    -> Backing
  {
    let p12 = try NIOSSLPKCS12Bundle(buffer: Array(pkcs12Data), passphrase: passphrase?.utf8)
    guard let cert = p12.certificateChain.first else {
      throw CertbotError.certificateLoadFailed(reason: .noValidCertificate)
    }
    let x509 = try Certificate(derEncoded: cert.toDERBytes())
    let commonName =
      x509.subject
      .compactMap { rdn in rdn.first(where: { $0.type == .RDNAttributeType.commonName }) }
      .first?
      .description ?? ""
    return Backing(
      representation: x509,
      commonName: commonName,
      passphrase: passphrase,
      base64EncodedP12String: pkcs12Data.base64EncodedString()
    )
  }

  #if swift(>=6.2)
    /// Generate new certificate using specified passphrase strategy.
    ///
    /// This will perform certificate generation, after success content will be updated.
    /// - Parameter strategy: Strategy for how to privide PKCS#12 passphrase. Defaults to `.auto`.
    ///
    @concurrent public func generate(using strategy: PassphraseStrategy = .auto) async throws {
      try await self._generate(using: strategy)
    }
  #else
    /// Generate new certificate using specified passphrase strategy.
    ///
    /// This will perform certificate generation, after success content will be updated.
    /// - Parameter strategy: Strategy for how to privide PKCS#12 passphrase. Defaults to `.auto`.
    ///
    nonisolated public func generate(using strategy: PassphraseStrategy = .auto) async throws {
      try await self._generate(using: strategy)
    }
  #endif

  private func _generate(using strategy: PassphraseStrategy = .auto) async throws {
    if generatingTask == nil || generatingTask?.isCancelled == true {
      generatingTask = Task {
        try await self.generate0(using: strategy)
      }
    }

    guard let task = generatingTask else { return }

    do {
      let backing = try await task.value
      self.backing = backing
      self._isTrusted = try self.trustEvaluate(certificate: backing.representation)
      generatingTask = nil
      logger.trace("Generate certificate success")
      return
    } catch {
      logger.trace("Generate certificate failed with error: \(error)")
      throw error
    }
  }

  #if swift(>=6.2)
    @concurrent private func generate0(using strategy: PassphraseStrategy = .auto) async throws
      -> Backing
    {
      return try await self._generate0(using: strategy)
    }
  #else
    nonisolated private func generate0(using strategy: PassphraseStrategy = .auto) async throws
      -> Backing
    {
      return try await self._generate0(using: strategy)
    }
  #endif

  nonisolated private func _generate0(using strategy: PassphraseStrategy = .auto) async throws
    -> Backing
  {
    let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)

    let serialNumber = Certificate.SerialNumber()
    let notValidBefore = Date()

    let passphrase: String
    switch strategy {
    case .auto:
      passphrase = ByteBuffer(
        bytes: Array(repeating: UInt8.zero, count: 4).map { _ in
          UInt8.random(in: 0...UInt8.max)
        }
      ).hexDump(format: .compact).uppercased()
    case .custom(let value):
      passphrase = value
    }

    let commonName = CommonName("Netbot Generated CA \(passphrase)")

    let issuer = try DistinguishedName {
      OrganizationName("Netbot")
      commonName
    }

    let subject = issuer

    let extensions = try Certificate.Extensions {
      Critical(
        KeyUsage(digitalSignature: true, keyCertSign: true, cRLSign: true)
      )

      try ExtendedKeyUsage([.serverAuth, .clientAuth])

      Critical(
        BasicConstraints.isCertificateAuthority(maxPathLength: 0)
      )
    }

    let x509 = try Certificate(
      version: .v3,
      serialNumber: serialNumber,
      publicKey: .init(privateKey.publicKey),
      notValidBefore: notValidBefore,
      notValidAfter: notValidBefore.addingTimeInterval(60 * 60 * 24 * 365),
      issuer: issuer,
      subject: subject,
      signatureAlgorithm: .sha256WithRSAEncryption,
      extensions: extensions,
      issuerPrivateKey: .init(privateKey)
    )

    var serializer = DER.Serializer()
    try serializer.serialize(x509)

    return Backing(
      representation: x509,
      commonName: commonName.name,
      passphrase: passphrase,
      base64EncodedP12String: try self.base64EncodedString(
        certBytes: serializer.serializedBytes,
        key: privateKey,
        passphrase: passphrase
      )
    )
  }

  /// Get base64 encoded PKCS#12 bundle string with specified cert key and passphrase.
  nonisolated private func base64EncodedString(
    certBytes: [UInt8],
    key: _RSA.Signing.PrivateKey,
    passphrase: String? = nil
  ) throws -> String {
    let p12 = try NIOSSLPKCS12Bundle(
      certificateChain: [NIOSSLCertificate(bytes: certBytes, format: .der)],
      privateKey: NIOSSLPrivateKey(bytes: Array(key.derRepresentation), format: .der)
    )
    let bytes = try p12.serialize(passphrase: [])
    return Data(bytes).base64EncodedString()
  }

  #if swift(>=6.2)
    /// Install and trust loaded or generated certificate.
    @concurrent public func trustLoadedCertificate() async throws {
      try await self._trustLoadedCertificate()
    }
  #else
    /// Install and trust loaded or generated certificate.
    nonisolated public func trustLoadedCertificate() async throws {
      try await self._trustLoadedCertificate()
    }
  #endif

  #if canImport(Security)
    nonisolated private func _trustLoadedCertificate() async throws {
      guard let backing = await backing, let certificate = try backing.certificate else { return }

      var status: OSStatus
      let attributes: [CFString: Any] = [
        kSecClass: kSecClassCertificate,
        kSecValueRef: certificate,
        kSecAttrLabel: backing.commonName,
      ]

      status = SecItemAdd(attributes as CFDictionary, nil)
      guard status == errSecSuccess || status == errSecDuplicateItem else {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
        self.logger.trace("Install certificate failed with error: \(message)")
        throw
          CertbotError
          .certificateTrustFailed(reason: .system(code: Int(status), reason: message))
      }

      #if os(macOS)
        let trustSettings = [kSecTrustSettingsResult: SecTrustSettingsResult.trustRoot.rawValue]
        status = SecTrustSettingsSetTrustSettings(certificate, .user, trustSettings as CFTypeRef)
        guard status == errSecSuccess else {
          let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
          self.logger.trace("Trust certificate failed with error: \(message)")
          throw CertbotError.certificateTrustFailed(
            reason: .system(code: Int(status), reason: message))
        }

        self.logger.trace("Install and trust certificate success")
      #endif

      let isTrusted = try self.trustEvaluate(certificate: backing.representation)

      await MainActor.run {
        self._isTrusted = isTrusted
      }
    }
  #else
    nonisolated private func _trustLoadedCertificate() async throws {
      // TODO: Trust Evaluation
      throw CertbotError.operationUnsupported
    }
  #endif

  /// Sectrust evaluate.
  #if canImport(Security)
    nonisolated private func trustEvaluate(certificate: Certificate) throws -> Bool {
      var serializer = DER.Serializer()
      try serializer.serialize(certificate)
      guard
        let cert = SecCertificateCreateWithData(nil, Data(serializer.serializedBytes) as CFData)
      else {
        self.logger.error("Generate certificate failed with error: data corrupted")
        return false
      }

      var trust: SecTrust?
      let status = SecTrustCreateWithCertificates(cert, SecPolicyCreateBasicX509(), &trust)
      guard status == errSecSuccess else {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
        logger.error("Trust evaluating failed with error: \(message)")
        throw CertbotError.certificateTrustFailed(
          reason: .system(code: Int(status), reason: message))
      }

      guard let trust else {
        logger.error("Trust evaluating failed with error: unable to create trust")
        return false
      }

      var error: CFError?
      guard SecTrustEvaluateWithError(trust, &error) else {
        return false
      }

      guard let error else {
        return true
      }

      let message = CFErrorCopyDescription(error)
      logger.trace("Trust evaluating failed with error: \(String(describing: message))")
      throw
        CertbotError
        .certificateTrustFailed(
          reason: .system(code: CFErrorGetCode(error), reason: message as? String))
    }
  #else
    nonisolated private func trustEvaluate(certificate: Certificate) throws -> Bool {
      // TODO: Trust Evaluation
      throw CertbotError.operationUnsupported
    }
  #endif
}
