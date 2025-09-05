//
// See LICENSE.txt for license information
//

import Anlzr
import CNIOBoringSSL
import NESS
import NIOSSL
import SwiftASN1
import X509
import _CryptoExtras
import _PreferenceSupport
import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import class Foundation.UserDefaults
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension Profile {

  func asForwardingRules() -> [any ForwardingRuleConvertible] {
    var lazyProxies = self.lazyProxies
    lazyProxies.append(contentsOf: [
      AnyProxy(name: "DIRECT", source: .builtin, kind: .direct),
      AnyProxy(name: "REJECT", source: .builtin, kind: .reject),
      AnyProxy(name: "REJECT-TINYGIF", source: .builtin, kind: .rejectTinyGIF),
    ])

    return lazyForwardingRules.compactMap { data in
      // First we found the proxy whitch name match the rule's foreignKey in proxies. If there is no
      // matched proxy then we should found it in policy groups.
      var proxy: AnyProxy? = lazyProxies.first { $0.name == data.foreignKey }

      if proxy == nil {
        if let name = lazyProxyGroups.first(where: { $0.name == data.foreignKey })?.name {
          // Resolve current selected proxy for this group.
          var records: [String: String] = [:]
          let key = Prefs.Name.selectionRecordForGroups
          if let data = UserDefaults.applicationGroup?.string(forKey: key)?.data(using: .utf8) {
            records = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
          }
          if let foreignKey = records[name] {
            proxy = lazyProxies.first { $0.name == foreignKey }
          }
        }
      }

      guard let forwardProtocol = proxy?.asForwardProtocol() else {
        return nil
      }

      return data.asForwardingRule(forwardProtocol)
    }
  }

  func asForwardProtocol() -> any ForwardProtocolConvertible {
    var records: [String: String] = [:]
    let store = UserDefaults.applicationGroup
    let key = Prefs.Name.selectionRecordForGroups
    if let data = store?.string(forKey: key)?.data(using: .utf8) {
      records = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    let fallback = AnyProxy(name: "DIRECT", source: .builtin, kind: .direct)

    guard let name = records["Global Proxies"] else {
      return fallback.asForwardProtocol()
    }

    let lazyProxies =
      [
        fallback,
        AnyProxy(name: "REJECT", source: .builtin, kind: .reject),
        AnyProxy(name: "REJECT-TINYGIF", source: .builtin, kind: .rejectTinyGIF),
      ] + self.lazyProxies

    if let lazyProxy = lazyProxies.first(where: { $0.name == name }) {
      return lazyProxy.asForwardProtocol()
    }

    guard let lazyProxyGroup = lazyProxyGroups.first(where: { $0.name == name }) else {
      return fallback.asForwardProtocol()
    }

    guard let name = records[lazyProxyGroup.name],
      let lazyProxy = lazyProxies.first(where: { $0.name == name })
    else {
      return fallback.asForwardProtocol()
    }
    return lazyProxy.asForwardProtocol()
  }

  func asDecryptionPKCS12Bundle0() throws -> NIOSSLPKCS12Bundle? {
    if #available(SwiftStdlib 5.5, *) {
      return try asDecryptionPKCS12Bundle0(notValidBefore: .now)
    } else {
      return try asDecryptionPKCS12Bundle0(notValidBefore: .init())
    }
  }

  func asDecryptionPKCS12Bundle0(notValidBefore: Date) throws -> NIOSSLPKCS12Bundle? {
    guard let data = Data(base64Encoded: base64EncodedP12String) else {
      return nil
    }

    // NIOSSL does not provide public convert function for convert NIOSSLPrivateKey to der bytes,
    // so we need fallback to use low-level C API to extract CA and private key.
    let buffer = Array(data)
    let p12 = buffer.withUnsafeBytes { pointer -> OpaquePointer? in
      let bio = CNIOBoringSSL_BIO_new_mem_buf(pointer.baseAddress, pointer.count)!
      defer {
        CNIOBoringSSL_BIO_free(bio)
      }
      return CNIOBoringSSL_d2i_PKCS12_bio(bio, nil)
    }
    defer {
      p12.map { CNIOBoringSSL_PKCS12_free($0) }
    }

    guard let p12 else {
      throw BoringSSLError.unknownError(BoringSSLError.buildErrorStack())
    }

    var pkey: OpaquePointer? = nil  // <EVP_PKEY>
    var cert: OpaquePointer? = nil  // <X509>

    let rc = passphrase.withCString { passphrase in
      CNIOBoringSSL_PKCS12_parse(p12, passphrase, &pkey, &cert, nil)
    }
    guard rc == 1 else {
      throw BoringSSLError.unknownError(BoringSSLError.buildErrorStack())
    }

    // Successfully parsed, let's unpack. The key and cert are mandatory,
    // the ca stack is not.
    guard let x509 = cert, let pkey else {
      fatalError("Failed to obtain cert and pkey from a PKC12 file")
    }
    defer {
      CNIOBoringSSL_EVP_PKEY_free(pkey)
      CNIOBoringSSL_X509_free(x509)
    }

    let issuer = try {
      guard let bio = CNIOBoringSSL_BIO_new(CNIOBoringSSL_BIO_s_mem()) else {
        fatalError("Failed to malloc for a BIO handler")
      }
      defer {
        CNIOBoringSSL_BIO_free(bio)
      }

      let rc = CNIOBoringSSL_i2d_X509_bio(bio, x509)
      guard rc == 1 else {
        let errorStack = BoringSSLError.buildErrorStack()
        throw BoringSSLError.unknownError(errorStack)
      }

      var dataPtr: UnsafeMutablePointer<CChar>? = nil
      let length = CNIOBoringSSL_BIO_get_mem_data(bio, &dataPtr)

      guard let bytes = dataPtr.map({ UnsafeRawBufferPointer(start: $0, count: length) }) else {
        fatalError("Failed to map bytes from a certificate")
      }

      return try Certificate(derEncoded: Array(bytes)).subject
    }()

    let issuerPrivateKey = try {
      guard let bio = CNIOBoringSSL_BIO_new(CNIOBoringSSL_BIO_s_mem()) else {
        fatalError("Failed to malloc for a BIO handler")
      }
      defer {
        CNIOBoringSSL_BIO_free(bio)
      }

      let rc = CNIOBoringSSL_i2d_PrivateKey_bio(bio, pkey)
      guard rc == 1 else {
        let errorStack = BoringSSLError.buildErrorStack()
        throw BoringSSLError.unknownError(errorStack)
      }

      var dataPtr: UnsafeMutablePointer<CChar>? = nil
      let length = CNIOBoringSSL_BIO_get_mem_data(bio, &dataPtr)

      guard let bytes = dataPtr.map({ UnsafeRawBufferPointer(start: $0, count: length) }) else {
        fatalError("Failed to map bytes from a private key")
      }

      let issuerPrivateKey = try Certificate.PrivateKey(
        _RSA.Signing.PrivateKey(derRepresentation: bytes))
      return issuerPrivateKey
    }()

    // Issuer new self-signed certificates and private key for HTTPS decryption.
    let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
    let subject = try DistinguishedName {
      CommonName("*")
    }
    let extensions = try Certificate.Extensions {
      SubjectAlternativeNames(hostnames.map { .dnsName($0) })
    }
    let certificate = try Certificate(
      version: .v3,
      serialNumber: .init(),
      publicKey: .init(privateKey.publicKey),
      notValidBefore: notValidBefore,
      notValidAfter: notValidBefore.addingTimeInterval(60 * 60 * 24 * 30),
      issuer: issuer,
      subject: subject,
      signatureAlgorithm: .sha256WithRSAEncryption,
      extensions: extensions,
      issuerPrivateKey: issuerPrivateKey
    )
    var serializer = DER.Serializer()
    try serializer.serialize(certificate)

    return try NIOSSLPKCS12Bundle(
      certificateChain: [NIOSSLCertificate(bytes: serializer.serializedBytes, format: .der)],
      privateKey: .init(bytes: Array(privateKey.derRepresentation), format: .der)
    )
  }

  func asDecryptionPKCS12Bundle() throws -> NIOSSLPKCS12Bundle? {
    if #available(SwiftStdlib 5.5, *) {
      return try asDecryptionPKCS12Bundle(notValidBefore: .now)
    } else {
      return try asDecryptionPKCS12Bundle(notValidBefore: .init())
    }
  }

  func asDecryptionPKCS12Bundle(notValidBefore: Date) throws -> NIOSSLPKCS12Bundle? {
    // Step 1: Decode and extract CA cert & key
    guard let data = Data(base64Encoded: base64EncodedP12String) else {
      return nil
    }

    let p12 = try NIOSSLPKCS12Bundle(buffer: Array(data), passphrase: passphrase.utf8)
    guard let caCert = p12.certificateChain.first else {
      return nil
    }
    let caPKey = p12.privateKey

    // Step 2: Extract CA subject (issuer DN)
    let issuer = try Certificate(derEncoded: caCert.toDERBytes()).subject

    // Step 3: Extract CA private key
    let caPrivateKey = try Certificate.PrivateKey(
      _RSA.Signing.PrivateKey(derRepresentation: caPKey.derBytes)
    )

    // Step 4: Generate leaf key and leaf cert (signed by CA)
    let leafPrivateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
    let subject = try DistinguishedName { CommonName("*") }
    let extensions = try Certificate.Extensions {
      SubjectAlternativeNames(hostnames.map { .dnsName($0) })
    }
    let leafCert = try Certificate(
      version: .v3,
      serialNumber: .init(),
      publicKey: .init(leafPrivateKey.publicKey),
      notValidBefore: notValidBefore,
      notValidAfter: notValidBefore.addingTimeInterval(60 * 60 * 24 * 30),
      issuer: issuer,
      subject: subject,
      signatureAlgorithm: .sha256WithRSAEncryption,
      extensions: extensions,
      issuerPrivateKey: caPrivateKey
    )
    var leafSerializer = DER.Serializer()
    try leafSerializer.serialize(leafCert)

    // Step 5: Return PKCS12 bundle with chain [leaf], private key = leaf
    return try NIOSSLPKCS12Bundle(
      certificateChain: [NIOSSLCertificate(bytes: leafSerializer.serializedBytes, format: .der)],
      privateKey: .init(bytes: Array(leafPrivateKey.derRepresentation), format: .der)
    )
  }
}

@available(SwiftStdlib 5.3, *)
extension AnyProxy {

  func asForwardProtocol() -> any ForwardProtocolConvertible {
    let forwardProtocol: any ForwardProtocolConvertible
    switch kind {
    case .direct:
      forwardProtocol = .direct
    case .rejectTinyGIF:
      forwardProtocol = .rejectTinyGIF
    case .reject:
      forwardProtocol = .reject
    case .https:
      let passwordReference = passwordReference
      forwardProtocol = ForwardProtocolHTTP(
        name: name,
        serverAddress: serverAddress,
        port: port,
        passwordReference: passwordReference,
        authenticationRequired: authenticationRequired,
        forceHTTPTunneling: forceHTTPTunneling,
        tls: tls
      )
    case .http:
      let passwordReference = passwordReference
      forwardProtocol = ForwardProtocolHTTP(
        name: name,
        serverAddress: serverAddress,
        port: port,
        passwordReference: passwordReference,
        authenticationRequired: authenticationRequired,
        forceHTTPTunneling: forceHTTPTunneling,
        tls: .init()
      )
    case .socks5OverTLS:
      forwardProtocol = ForwardProtocolSOCKS5(
        name: name,
        serverAddress: serverAddress,
        port: port,
        username: username,
        passwordReference: passwordReference,
        authenticationRequired: authenticationRequired,
        tls: tls
      )
    case .socks5:
      forwardProtocol = ForwardProtocolSOCKS5(
        name: name,
        serverAddress: serverAddress,
        port: port,
        username: username,
        passwordReference: passwordReference,
        authenticationRequired: authenticationRequired,
        tls: .init()
      )
    case .shadowsocks:
      forwardProtocol = ForwardProtocolSS(
        name: name,
        serverAddress: serverAddress,
        port: port,
        algorithm: .init(rawValue: algorithm.rawValue) ?? .aes256Gcm,
        passwordReference: passwordReference
      )
    case .vmess:
      if #available(SwiftStdlib 5.7, *) {
        forwardProtocol = ForwardProtocolVMESS(
          name: name,
          serverAddress: serverAddress,
          port: port,
          userID: UUID(uuidString: username)!,
          ws: ws,
          tls: tls
        )
      } else {
        // TODO: Fallback to SwiftStdlib 5.3
        forwardProtocol = .direct
      }
    }
    return forwardProtocol
  }
}

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule {

  func asForwardingRule(_ forwardProtocol: any ForwardProtocolConvertible)
    -> any ForwardingRuleConvertible
  {
    switch kind {
    case .domain:
      return DomainForwardingRule(domain: value, forwardProtocol: forwardProtocol)
    case .domainKeyword:
      return DomainKeywordForwardingRule(
        domainKeyword: value, forwardProtocol: forwardProtocol)
    case .domainSuffix:
      return DomainSuffixForwardingRule(
        domainSuffix: value, forwardProtocol: forwardProtocol)
    case .domainset:
      return DomainsetForwardingRule(
        originalURLString: value, forwardProtocol: forwardProtocol)
    case .ruleset:
      return RulesetForwardingRule(
        originalURLString: value, forwardProtocol: forwardProtocol)
    case .geoip:
      return GeoIPForwardingRule(
        db: nil, countryCode: value, forwardProtocol: forwardProtocol)
    case .ipcidr:
      return IPCIDRForwardingRule(
        classlessInterDomainRouting: value, forwardProtocol: forwardProtocol)
    case .final:
      return FinalForwardingRule(value, forwardProtocol: forwardProtocol)
    }
  }
}
