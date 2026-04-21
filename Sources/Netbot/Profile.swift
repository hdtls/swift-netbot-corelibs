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

import NESS
import NIOSSL
import NetbotLite
import SwiftASN1
import X509
import _PreferenceSupport
import _ProfileSupport

#if canImport(CryptoKit)
  import CryptoExtras
#else
  import _CryptoExtras
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import class Foundation.UserDefaults
#else
  import Foundation
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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
          if let data = UserDefaults.__shared?.string(forKey: key)?.data(using: .utf8) {
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
    let store = UserDefaults.__shared
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

  func asDecryptionPKCS12Bundle() throws -> NIOSSLPKCS12Bundle? {
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

    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      let notValidBefore: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
    #else
      let notValidBefore = Date.now
    #endif

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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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
      #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
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
          // TODO: ForwardProtocolVMESS BackDeploy
          forwardProtocol = .direct
        }
      #else
        forwardProtocol = ForwardProtocolVMESS(
          name: name,
          serverAddress: serverAddress,
          port: port,
          userID: UUID(uuidString: username)!,
          ws: ws,
          tls: tls
        )
      #endif
    }
    return forwardProtocol
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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
        uncheckedBounds: value, forwardProtocol: forwardProtocol)
    case .processName:
      return ProcessForwardingRule(processName: value, forwardProtocol: forwardProtocol)
    case .final:
      return FINALForwardingRule(value, forwardProtocol: forwardProtocol)
    }
  }
}
