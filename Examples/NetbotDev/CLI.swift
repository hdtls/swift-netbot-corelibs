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

import ArgumentParser
import MaxMindDB
import Netbot

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
@main
struct Application: AsyncParsableCommand {

  @Option(help: "Outbound mode.")
  var outboundMode: OutboundMode = .direct

  @Option(help: "Enabled HTTP capabilities.")
  var enabledHTTPCapabilities: CapabilityFlags = []

  @Argument(
    help: "MaxMind DB file path. If omitted, all GEOIP rule will be disabled",
    completion: .file(), transform: URL.init(fileURLWithPath:))
  var maxminddb: URL? = nil

  @Argument(
    help: "Configuration file path. If omitted, default profile will be used.",
    completion: .file(), transform: URL.init(fileURLWithPath:))
  var configuration: URL? = nil

  func run() async throws {
    var profile = Profile()
    if let configuration {
      profile = try Profile(contentsOf: configuration)
    }

    var db: MaxMindDB?
    if let path = self.maxminddb?.path() {
      db = try MaxMindDB(file: path, mode: .mmap)
    }

    let bot = AnalyzeBot()

    var defaults: [String: String] = [:]
    switch outboundMode {
    case .direct:
      break
    case .globalProxy:
      // Choose the first one as the selected proxy in proxy group.
      defaults = profile.lazyProxyGroups.reduce(into: [String: String]()) { partialResult, group in
        partialResult[group.name] = group.lazyProxies.first
      }
      defaults["Global Proxies"] = profile.lazyProxies.first.map(\.name)
    case .ruleBased:
      defaults = profile.lazyProxyGroups.reduce(into: [String: String]()) { partialResult, group in
        partialResult[group.name] = group.lazyProxies.first
      }
    }

    await bot.setOutboundMode(outboundMode)
    await bot.setEnabledHTTPCapabilities(enabledHTTPCapabilities)
    await bot.setForwardProtocol(profile.makeForwardProtocol(defaults: defaults))
    await bot.setForwardingRules(profile.makeForwardingRules(defaults: defaults, maxminddb: db))
    await bot.setDecryptionSSLPKCS12Bundle(try? profile.decryptionSSLPKCS12Bundle)

    try await bot.run()
  }
}

@available(SwiftStdlib 6.0, *)
extension OutboundMode: ExpressibleByArgument {}

@available(SwiftStdlib 6.0, *)
extension CapabilityFlags: ExpressibleByArgument {}
