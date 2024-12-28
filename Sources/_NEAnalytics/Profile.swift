//
// See LICENSE.txt for license information
//

import Anlzr

#if canImport(FoundationEssentials)
  private import FoundationEssentials
  private import class Foundation.UserDefaults
#else
  private import Foundation
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
}

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
      forwardProtocol = ForwardProtocolVMESS(
        name: name,
        serverAddress: serverAddress,
        port: port,
        userID: UUID(uuidString: username)!,
        ws: ws,
        tls: tls
      )
    }
    return forwardProtocol
  }
}

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
