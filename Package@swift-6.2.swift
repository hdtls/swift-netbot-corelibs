// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
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

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-netbot-corelibs",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
  ],
  products: [
    .library(name: "Dashboard", targets: ["Dashboard"]),
    .library(name: "Netbot", targets: ["Netbot"]),
    .library(name: "NetbotDaemons", targets: ["NetbotDaemons"]),
    .library(name: "NetbotKit", targets: ["NetbotKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-asn1.git", from: "1.6.0"),
    .package(url: "https://github.com/apple/swift-certificates.git", from: "1.18.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.11.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.97.1"),
    .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.36.1"),
    .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.33.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.5.1"),
    .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.4.1"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.11.1"),
  ],
  targets: [
    .macro(
      name: "_EditableMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .macro(
      name: "CoWOptimizationMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .macro(
      name: "SynchronizationMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "_DNSSupport",
      dependencies: [
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NEAddressProcessing", package: "swift-netbot-protoimpl"),
      ]
    ),
    .target(
      name: "_PreferenceSupport",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Preference", package: "swift-preference"),
      ]
    ),
    .target(name: "_PrivilegeSupport"),
    .target(
      name: "_ProfileSupport",
      dependencies: [
        "CoWOptimization",
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .target(name: "CNELwIP"),
    .target(name: "CoWOptimization", dependencies: ["CoWOptimizationMacros"]),
    .target(
      name: "Dashboard",
      dependencies: [
        "_PreferenceSupport",
        "NetbotLiteData",
        .product(name: "NIOCore", package: "swift-nio"),
      ]
    ),
    .target(
      name: "Netbot",
      dependencies: [
        "_DNSSupport",
        "_PreferenceSupport",
        "_ProfileSupport",
        "NetbotDaemons",
        "NetbotLite",
        "NetbotLiteData",
        "CNELwIP",
        "CoWOptimization",
        .product(name: "MaxMindDB", package: "swift-maxminddb"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "X509", package: "swift-certificates"),
        .product(name: "Alamofire", package: "Alamofire"),
        .product(name: "_CryptoExtras", package: "swift-crypto"),
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "Tracing", package: "swift-distributed-tracing"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "NIOWebSocket", package: "swift-nio"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
        .product(name: "NIOHTTPCompression", package: "swift-nio-extras"),
        .product(name: "NIOExtras", package: "swift-nio-extras"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "NEHTTP", package: "swift-netbot-protoimpl"),
        .product(name: "NESOCKS", package: "swift-netbot-protoimpl"),
        .product(name: "NESS", package: "swift-netbot-protoimpl"),
        .product(name: "NEVMESS", package: "swift-netbot-protoimpl"),
      ]
    ),
    .target(name: "NetbotDaemons", dependencies: ["_PrivilegeSupport"]),
    .target(
      name: "NetbotKit",
      dependencies: [
        "_EditableMacros",
        "_PreferenceSupport",
        "_ProfileSupport",
        "NetbotLiteData",
        "Dashboard",
        .product(name: "_CryptoExtras", package: "swift-crypto"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "SwiftASN1", package: "swift-asn1"),
        .product(name: "X509", package: "swift-certificates"),
        .product(name: "Alamofire", package: "Alamofire"),
      ]
    ),
    .target(
      name: "NetbotLite",
      dependencies: [
        "NetbotLiteData",
        .product(name: "_CryptoExtras", package: "swift-crypto"),
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "Tracing", package: "swift-distributed-tracing"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "NIOWebSocket", package: "swift-nio"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
        .product(name: "NIOHTTPCompression", package: "swift-nio-extras"),
        .product(name: "NIOExtras", package: "swift-nio-extras"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "NEHTTP", package: "swift-netbot-protoimpl"),
        .product(name: "NESOCKS", package: "swift-netbot-protoimpl"),
        .product(name: "NESS", package: "swift-netbot-protoimpl"),
        .product(name: "NEVMESS", package: "swift-netbot-protoimpl"),
      ]),
    .target(
      name: "NetbotLiteData",
      dependencies: [
        "SynchronizationMacros",
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "NEAddressProcessing", package: "swift-netbot-protoimpl"),
        .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
      ]
    ),
    .testTarget(name: "_DNSSupportTests", dependencies: ["_DNSSupport"]),
    .testTarget(
      name: "_EditableMacrosTests",
      dependencies: [
        "_EditableMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(name: "_ProfileSupportTests", dependencies: ["_ProfileSupport"]),
    .testTarget(
      name: "CoWOptimizationMacrosTests",
      dependencies: [
        "CoWOptimizationMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(name: "DashboardTests", dependencies: ["Dashboard"]),
    .testTarget(
      name: "NetbotTests",
      dependencies: [
        "Netbot",
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOEmbedded", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "NIOWebSocket", package: "swift-nio"),
      ],
      exclude: ["External Resource"]
    ),
    .testTarget(name: "NetbotKitTests", dependencies: ["NetbotKit"]),
    .testTarget(name: "NetbotLiteDataTests", dependencies: ["NetbotLiteData"]),
    .testTarget(name: "NetbotLiteTests", dependencies: ["NetbotLite"]),
    .testTarget(
      name: "SynchronizationMacrosTests",
      dependencies: [
        "SynchronizationMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)

if Context.environment["NETBOT_REQUIRES_LOCAL_PACKAGE_DEPENDENCIES"] != nil {
  package.dependencies += [
    .package(path: "../swift-nio-transport-services"),
    .package(path: "../swift-netbot-protoimpl"),
    .package(path: "../swift-maxminddb"),
    .package(path: "../swift-preference"),
  ]
} else {
  package.dependencies += [
    .package(
      url: "https://github.com/hdtls/swift-nio-transport-services.git", branch: "release/2.0"),
    .package(url: "https://github.com/hdtls/swift-netbot-protoimpl.git", branch: "main"),
    .package(url: "https://github.com/hdtls/swift-maxminddb.git", from: "1.3.0"),
    .package(url: "https://github.com/hdtls/swift-preference.git", from: "1.0.0"),
  ]
}

#if canImport(Darwin)
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.3.0")
  ]
#else
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-crypto.git", "3.12.0"..<"3.13.0")
  ]
#endif

for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(.define("NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5"))
  settings.append(.enableExperimentalFeature("StrictConcurrency=complete"))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 5.5:iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0"
    ))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 5.7:iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0"
    ))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 5.9:iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0"
    ))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 6.0:iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0"
    ))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 6.2:macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0"
    ))
  target.swiftSettings = settings
}

for target in package.targets {
  switch target.type {
  case .regular, .test, .executable:
    var settings = target.swiftSettings ?? []
    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    settings.append(.enableUpcomingFeature("MemberImportVisibility"))
    target.swiftSettings = settings
  case .macro, .plugin, .system, .binary:
    ()  // not applicable
  @unknown default:
    ()  // we don't know what to do here, do nothing
  }
}
