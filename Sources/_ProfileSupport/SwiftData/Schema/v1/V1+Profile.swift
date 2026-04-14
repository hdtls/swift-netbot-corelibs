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

#if canImport(SwiftData)
  import Foundation
  import Logging
  import SwiftData

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    @Model public class _Profile {

      //            //      @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *)
      //      @Unique<_Profile>([\.url])

      /// The url the resource was storaged..
      @Attribute(.unique)
      public var url = URL.profile

      /// Log level use for `Logger`.`
      public var logLevel = Logger.Level.info

      /// DNS settings.
      public var dnsSettings = AnyDNSSettings(servers: [])

      /// Exceptions use for system proxy.
      public var exceptions: [String] {
        get { _exceptions.split(separator: ",").map(String.init) }
        set { _exceptions = newValue.joined(separator: ",") }
      }
      public var _exceptions: String = ""

      /// Http listen address use for system http proxy.
      public var httpListenAddress = "0.0.0.0"

      /// Http listen port use for system http proxy
      public var httpListenPort: Int?

      /// Socks listen address use for system socks proxy.
      public var socksListenAddress = "0.0.0.0"

      /// Socks listen port use for system socks proxy.
      public var socksListenPort: Int?

      /// A boolean value that determine whether system proxy should exclude simple hostnames.
      public var excludeSimpleHostnames = false

      /// A boolean value determine whether ssl should skip server cerfitication verification. Default is false.
      public var skipCertificateVerification = false

      /// Hostnames that should perform MitM.
      public var hostnames: [String] {
        get { _hostnames.split(separator: ",").map(String.init) }
        set { _hostnames = newValue.joined(separator: ",") }
      }
      public var _hostnames: String = ""

      /// Base64 encoded CA P12 bundle.
      public var base64EncodedP12String = ""

      /// Passphrase for P12 bundle.
      public var passphrase = ""

      /// The time the resource content was last modified.
      public var contentModificationDate = Date.now

      /// Global internet connect quality test URL string.
      public var testURL: URL?

      /// Global proxy connect quality test URL string.
      public var proxyTestURL: URL?

      /// Timeout for network measurement.
      public var testTimeout = 5.0

      /// A boolean value determine whether show error pages for REJECT policy errors should be disabled.
      public var dontAlertRejectErrors = false

      /// A boolean value determine whether remote access should be disabled.
      public var dontAllowRemoteAccess = false

      /// The time the resource was created.
      public var creationDate = Date.now

      /// The proxies included in this profile.
      @Relationship(inverse: \_AnyProxy.lazyProfile)
      public var lazyProxies: [_AnyProxy] = []

      /// The policy groups included in this profile.
      @Relationship(inverse: \_AnyProxyGroup.lazyProfile)
      public var lazyProxyGroups: [_AnyProxyGroup] = []

      /// The rules included in this profile.
      @Relationship(inverse: \_AnyForwardingRule.lazyProfile)
      public var lazyForwardingRules: [_AnyForwardingRule] = []

      /// The DNS mappings included in this profile.
      @Relationship(inverse: \_DNSMapping.lazyProfile)
      public var lazyDNSMappings: [_DNSMapping] = []

      /// The URL rewriting included in this profile.
      @Relationship(inverse: \_URLRewrite.lazyProfile)
      public var lazyURLRewrites: [_URLRewrite] = []

      /// The HTTP fields rewriting included in this profile.
      @Relationship(inverse: \_HTTPFieldsRewrite.lazyProfile)
      public var lazyHTTPFieldsRewrites: [_HTTPFieldsRewrite] = []

      /// The stubbed HTTP responses included in this profile.
      @Relationship(inverse: \_StubbedHTTPResponse.lazyProfile)
      public var lazyStubbedHTTPResponses: [_StubbedHTTPResponse] = []

      /// Initialize a `_Profile` using default url.
      public init() {}
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension Profile {

    public typealias PersistentModel = V1._Profile

    public init(persistentModel: PersistentModel) {
      self.init()
      url = persistentModel.url
      logLevel = persistentModel.logLevel
      dnsSettings = persistentModel.dnsSettings
      exceptions = persistentModel.exceptions
      httpListenAddress = persistentModel.httpListenAddress
      httpListenPort = persistentModel.httpListenPort
      socksListenAddress = persistentModel.socksListenAddress
      socksListenPort = persistentModel.socksListenPort
      excludeSimpleHostnames = persistentModel.excludeSimpleHostnames
      skipCertificateVerification = persistentModel.skipCertificateVerification
      hostnames = persistentModel.hostnames
      base64EncodedP12String = persistentModel.base64EncodedP12String
      passphrase = persistentModel.passphrase
      contentModificationDate = persistentModel.contentModificationDate
      testURL = persistentModel.testURL
      proxyTestURL = persistentModel.proxyTestURL
      testTimeout = persistentModel.testTimeout
      dontAlertRejectErrors = persistentModel.dontAlertRejectErrors
      dontAllowRemoteAccess = persistentModel.dontAllowRemoteAccess
      creationDate = persistentModel.creationDate

      // Also load the relationships.
      lazyProxies = persistentModel.lazyProxies
        .sorted(using: KeyPathComparator(\.creationDate))
        .map(AnyProxy.init(persistentModel:))

      lazyProxyGroups = persistentModel.lazyProxyGroups
        .sorted(using: KeyPathComparator(\.creationDate))
        .map(AnyProxyGroup.init(persistentModel:))

      lazyForwardingRules = persistentModel.lazyForwardingRules
        .sorted(using: KeyPathComparator(\.order))
        .map(AnyForwardingRule.init(persistentModel:))

      lazyDNSMappings = persistentModel.lazyDNSMappings
        .sorted(using: KeyPathComparator(\.creationDate))
        .map(DNSMapping.init(persistentModel:))

      lazyURLRewrites = persistentModel.lazyURLRewrites
        .sorted(using: KeyPathComparator(\.creationDate))
        .map(URLRewrite.init(persistentModel:))

      lazyHTTPFieldsRewrites = persistentModel.lazyHTTPFieldsRewrites
        .sorted(using: KeyPathComparator(\.creationDate))
        .map(HTTPFieldsRewrite.init)

      lazyStubbedHTTPResponses = persistentModel.lazyStubbedHTTPResponses
        .sorted(using: KeyPathComparator(\.creationDate))
        .map(StubbedHTTPResponse.init)
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._Profile {

    public func mergeValues(_ data: Profile) {
      url = data.url
      logLevel = data.logLevel
      dnsSettings = data.dnsSettings
      exceptions = data.exceptions
      httpListenAddress = data.httpListenAddress
      httpListenPort = data.httpListenPort
      socksListenAddress = data.socksListenAddress
      socksListenPort = data.socksListenPort
      excludeSimpleHostnames = data.excludeSimpleHostnames
      skipCertificateVerification = data.skipCertificateVerification
      hostnames = data.hostnames
      base64EncodedP12String = data.base64EncodedP12String
      passphrase = data.passphrase
      contentModificationDate = data.contentModificationDate
      testURL = data.testURL
      proxyTestURL = data.proxyTestURL
      testTimeout = data.testTimeout
      dontAlertRejectErrors = data.dontAlertRejectErrors
      dontAllowRemoteAccess = data.dontAllowRemoteAccess
      creationDate = data.creationDate
    }
  }
#endif
