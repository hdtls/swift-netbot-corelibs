// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

#if canImport(Darwin)
  import CryptoExtras
  import Foundation
  import NIOCore
  import Logging
  import Observation
  import Security
  import SwiftASN1
  import X509
  import NIOSSL

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  public enum CertbotError: Error {

    case dataCorrupted

    case missingData

    case syserr(code: any Sendable, description: String?)

    case boringsslerr(description: String?)

    case x509(description: String)
  }

  /// Certificate managment object.
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @MainActor @Observable final public class Certbot: @unchecked Sendable {

    private struct Backing: Sendable {

      let representation: Certificate
      var certificate: SecCertificate {
        get throws {
          var serializer = DER.Serializer()
          try serializer.serialize(representation)
          guard
            let cert = SecCertificateCreateWithData(nil, Data(serializer.serializedBytes) as CFData)
          else {
            throw CertbotError.dataCorrupted
          }
          return cert
        }
      }

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

    /// CA Certificate common name.
    public var commonName: String? {
      backing?.commonName
    }

    public var notValidBefore: Date? {
      backing?.representation.notValidBefore
    }

    public var notValidAfter: Date? {
      backing?.representation.notValidAfter
    }

    /// A boolean value determinse whether this certificate is expired.
    public var isExpired: Bool {
      guard let notValidBefore, let notValidAfter else {
        return true
      }
      let now = Date.now
      return now > notValidAfter || now < notValidBefore
    }

    /// Base64 encoded PKCS#12 bundle string.
    public var base64EncodedP12String: String {
      backing?.base64EncodedP12String ?? ""
    }

    /// Passphrase for PKCS#12 bundle.
    public var passphrase: String {
      backing?.passphrase ?? ""
    }

    public var isTrusted: Bool {
      _isTrusted
    }
    private var _isTrusted: Bool = false

    public var certificate: SecCertificate? {
      try? backing?.certificate
    }

    /// Logger for certbot.
    nonisolated public let logger = Logger(label: "Certbot")

    @ObservationIgnored private var generatingTask: Task<Backing, any Error>?

    /// Create an instance of `Certbot`.
    nonisolated public init() {

    }

    /// Load certificate from base64 encoded PKCS#12 bundle string.
    #if swift(>=6.2)
      @concurrent public func loadFromBase64EncodedP12String(
        _ base64String: String?, passphrase: String?
      )
        async throws
      {
        try await _loadFromBase64EncodedP12String(base64String, passphrase: passphrase)
      }
    #else
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
      guard let base64String, let buffer = Data(base64Encoded: base64String), !buffer.isEmpty
      else {
        self.logger.trace(
          "Load PKCS#12 bundle failed with error: data corrupted (\(base64String ?? "nil")")
        throw CertbotError.dataCorrupted
      }

      let backing = try self.loadFromP12Data(buffer, passphrase: passphrase)
      let isTrusted = try await self.trustEvaluate(certificate: backing.representation)

      await MainActor.run {
        self.backing = backing
        self._isTrusted = isTrusted
      }
    }

    /// Load certificate from url where PKCS#12 bundle saved.
    #if swift(>=6.2)
      @concurrent public func loadFromP12File(at url: URL, passphrase: String?) async throws {
        try await _loadFromP12File(at: url, passphrase: passphrase)
      }
    #else
      nonisolated public func loadFromP12File(at url: URL, passphrase: String?) async throws {
        try await _loadFromP12File(at: url, passphrase: passphrase)
      }
    #endif
    nonisolated private func _loadFromP12File(at url: URL, passphrase: String?) async throws {
      guard let data = try? Data(contentsOf: url) else {
        self.logger.trace(
          "Load PKCS#12 bundle failed with error: data corrupted (unable to load contents from url: \(url)"
        )
        throw CertbotError.dataCorrupted
      }
      let backing = try self.loadFromP12Data(data, passphrase: passphrase)
      let isTrusted = try await self.trustEvaluate(certificate: backing.representation)

      await MainActor.run {
        self.backing = backing
        self._isTrusted = isTrusted
      }
    }

    /// Load certificate from PKCS#12 bundle data.
    ///
    /// - Important: This operation will block IO.
    nonisolated private func loadFromP12Data(_ pkcs12Data: Data, passphrase: String?) throws
      -> Backing
    {
      var options: [String: Any] = [:]
      if let passphrase {
        options = [kSecImportExportPassphrase as String: passphrase]
      }

      var optionalItems: CFArray?
      var status = SecPKCS12Import(pkcs12Data as CFData, options as CFDictionary, &optionalItems)
      guard status == errSecSuccess else {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
        logger.trace("Load PKCS#12 bundle failed with error: \(message)")
        throw CertbotError.syserr(code: status, description: message)
      }

      guard let optionalItems, CFArrayGetCount(optionalItems) > 0 else {
        logger.trace("Load PKCS#12 bundle failed with error: data corrupted (empty bundle).")
        throw CertbotError.missingData
      }

      let items = optionalItems as NSArray

      guard let dictionary = items[0] as? NSDictionary else {
        logger.trace("Load PKCS#12 bundle failed with error: data corrupted (data format error).")
        throw CertbotError.dataCorrupted
      }

      guard let item = dictionary[kSecImportItemIdentity] else {
        logger.trace(
          "Load PKCS#12 bundle failed with error: data corrupted (missing identity data)."
        )
        throw CertbotError.missingData
      }

      let identity = item as! SecIdentity

      var cert: SecCertificate?
      status = SecIdentityCopyCertificate(identity, &cert)
      guard status == errSecSuccess else {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
        logger.trace("Load PKCS#12 bundle failed with error: \(message)")
        throw CertbotError.syserr(code: status, description: message)
      }

      guard let cert else {
        logger.trace(
          "Load PKCS#12 bundle failed with error: data corrupted (missing certificate data)."
        )
        throw CertbotError.missingData
      }

      var cn: CFString?
      status = SecCertificateCopyCommonName(cert, &cn)
      guard status == errSecSuccess else {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
        logger.trace("Load PKCS#12 bundle failed with error: \(message)")
        throw CertbotError.syserr(code: status, description: message)
      }

      let data = SecCertificateCopyData(cert) as Data

      let x509: Certificate
      do {
        x509 = try Certificate(derEncoded: ArraySlice(data))
      } catch let error as CertificateError {
        throw CertbotError.x509(description: error.localizedDescription)
      } catch {
        throw error
      }

      let commonName = cn != nil ? cn.unsafelyUnwrapped as String : ""

      return Backing(
        representation: x509,
        commonName: commonName,
        passphrase: passphrase,
        base64EncodedP12String: pkcs12Data.base64EncodedString()
      )
    }

    /// Generate new certificate using specified passphrase strategy.
    ///
    /// This will perform certificate generation, after success content will be updated.
    /// - Parameter strategy: Strategy for how to privide PKCS#12 passphrase. Defaults to `.auto`.
    #if swift(>=6.2)
      @concurrent public func generate(using strategy: PassphraseStrategy = .auto) async throws {
        try await self._generate(using: strategy)
      }
    #else
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
        self._isTrusted = try await self.trustEvaluate(certificate: backing.representation)
        generatingTask = nil
        logger.trace("Generate certificate success")
        return
      } catch let error as CertificateError {
        logger.trace("Generate certificate failed with error: \(error)")
        throw CertbotError.x509(description: error.localizedDescription)
      } catch let error as BoringSSLError {
        logger.trace("Generate certificate failed with error: \(error)")
        throw CertbotError.boringsslerr(description: error.localizedDescription)
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
    ///
    /// - Important: IO block operation.
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

    /// Install loaded or generated certificate and update trust settings.
    #if swift(>=6.2)
      @concurrent public func trustLoadedCertificate() async throws {
        try await self._trustLoadedCertificate()
      }
    #else
      nonisolated public func trustLoadedCertificate() async throws {
        try await self._trustLoadedCertificate()
      }
    #endif
    nonisolated private func _trustLoadedCertificate() async throws {
      guard let backing = await backing else { return }

      var status: OSStatus
      let attributes: [CFString: Any] = [
        kSecClass: kSecClassCertificate,
        kSecValueRef: try backing.certificate,
        kSecAttrLabel: backing.commonName,
      ]

      status = SecItemAdd(attributes as CFDictionary, nil)
      guard status == errSecSuccess || status == errSecDuplicateItem else {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
        self.logger.trace("Install certificate failed with error: \(message)")
        throw CertbotError.syserr(code: status, description: message)
      }

      #if os(macOS)
        let trustSettings = [kSecTrustSettingsResult: SecTrustSettingsResult.trustRoot.rawValue]
        status = SecTrustSettingsSetTrustSettings(
          try backing.certificate,
          .user,
          trustSettings as CFTypeRef
        )
        guard status == errSecSuccess else {
          let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
          self.logger.trace("Trust certificate failed with error: \(message)")
          throw CertbotError.syserr(code: status, description: message)
        }

        self.logger.trace("Install and trust certificate success")
      #endif

      let isTrusted = try await self.trustEvaluate(certificate: backing.representation)

      await MainActor.run {
        self._isTrusted = isTrusted
      }
    }

    /// Sectrust evaluate.
    ///
    /// - Important: This operation will block IO.
    #if swift(>=6.2)
      @concurrent private func trustEvaluate(certificate: Certificate) async throws -> Bool {
        try self._trustEvaluate(certificate: certificate)
      }
    #else
      nonisolated public func trustEvaluate(certificate: Certificate) async throws -> Bool {
        try self._trustEvaluate(certificate: certificate)
      }
    #endif
    nonisolated private func _trustEvaluate(certificate: Certificate) throws -> Bool {
      var serializer = DER.Serializer()
      try serializer.serialize(certificate)
      guard
        let cert = SecCertificateCreateWithData(nil, Data(serializer.serializedBytes) as CFData)
      else {
        self.logger.error("Generate certificate failed with error: data corrupted")
        throw CertbotError.dataCorrupted
      }

      var trust: SecTrust?
      let status = SecTrustCreateWithCertificates(cert, SecPolicyCreateBasicX509(), &trust)
      guard status == errSecSuccess else {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? ""
        logger.trace("Trust evaluating failed with error: \(message)")
        throw CertbotError.syserr(code: status, description: message)
      }

      guard let trust else {
        logger.trace("Trust evaluating failed with error: unable to create trust")
        throw CertbotError.missingData
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
      throw CertbotError.syserr(code: CFErrorGetCode(error), description: message as? String)
    }
  }
#endif
