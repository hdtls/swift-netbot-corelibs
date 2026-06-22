// swift-tools-version: 6.2
// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2024-2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

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
    .library(name: "NetbotDashboard", targets: ["NetbotDashboard"]),
    .library(name: "Netbot", targets: ["Netbot"]),
    .library(name: "NetbotXPC", targets: ["NetbotXPC"]),
    .library(name: "NetbotFrontend", targets: ["NetbotFrontend"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-asn1.git", from: "1.6.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.3.0"),
    .package(url: "https://github.com/apple/swift-certificates.git", from: "1.18.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.11.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.97.1"),
    .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.36.1"),
    .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.28.0"),
    .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.33.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.5.1"),
    .package(url: "https://github.com/apple/swift-metrics.git", from: "2.11.0"),
    .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.4.1"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.11.1"),

    // swift-syntax periodically publishes a new tag with a suffix of the format
    // "-prerelease-YYYY-MM-DD". We always want to use the most recent tag
    // associated with a particular Swift version, without needing to hardcode
    // an exact tag and manually keep it up-to-date. Specifying the suffix
    // "-latest" on this dependency is a workaround which causes Swift package
    // manager to use the lexicographically highest-sorted tag with the
    // specified semantic version, meaning the most recent "prerelease" tag will
    // always be used.
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "604.0.0-latest"),
  ],
  targets: [
    .macro(
      name: "CoWOptimizationMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .macro(
      name: "NetbotFrontendMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .macro(
      name: "NetbotSQLMacros",
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
    .target(name: "CNELwIP"),
    .target(name: "CoWOptimization", dependencies: ["CoWOptimizationMacros"]),
    .target(
      name: "Netbot",
      dependencies: [
        "CoWOptimization",
        "NetbotDNS",
        "NetbotLite",
        "NetbotLiteData",
        "NetbotPreferences",
        "NetbotProfile",
        "NetbotXPC",
        "SynchronizationExtras",
        .target(name: "CNELwIP", condition: .when(platforms: [.macOS])),
        .product(name: "MaxMindDB", package: "swift-maxminddb"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "X509", package: "swift-certificates"),
        .product(name: "Alamofire", package: "Alamofire"),
        .product(name: "CryptoExtras", package: "swift-crypto"),
        .product(name: "Tracing", package: "swift-distributed-tracing"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "NIOCore", package: "swift-nio"),
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
      ],
      exclude: ["DNS", "Preferences", "Profile"]
    ),
    .target(
      name: "NetbotDashboard",
      dependencies: [
        "NetbotLiteData",
        "NetbotPreferences",
        "SynchronizationExtras",
        .product(name: "Alamofire", package: "Alamofire"),
        .product(name: "NIOCore", package: "swift-nio"),
      ]
    ),
    .target(
      name: "NetbotDNS",
      dependencies: [
        "NetbotLite",
        "NetbotLiteData",
        "NetbotProfile",
        "SynchronizationExtras",
        .product(name: "Logging", package: "swift-log"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NEAddressProcessing", package: "swift-netbot-protoimpl"),
      ],
      path: "Sources/Netbot/DNS"
    ),
    .target(
      name: "NetbotFrontend",
      dependencies: [
        "NetbotDashboard",
        "NetbotFrontendMacros",
        "NetbotLiteData",
        "NetbotPreferences",
        "NetbotProfile",
        "SynchronizationExtras",
        .product(name: "CryptoExtras", package: "swift-crypto"),
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
        "SynchronizationExtras",
        .product(name: "CryptoExtras", package: "swift-crypto"),
        .product(name: "Metrics", package: "swift-metrics"),
        .product(name: "Tracing", package: "swift-distributed-tracing"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "NIOCore", package: "swift-nio"),
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
      ],
      exclude: ["Data"]
    ),
    .target(
      name: "NetbotLiteData",
      dependencies: [
        "NetbotSQL",
        "SynchronizationExtras",
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "NEAddressProcessing", package: "swift-netbot-protoimpl"),
      ],
      path: "Sources/NetbotLite/Data"
    ),
    .target(
      name: "NetbotPreferences",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Preference", package: "swift-preference"),
      ],
      path: "Sources/Netbot/Preferences"
    ),
    .target(
      name: "NetbotProfile",
      dependencies: [
        "CoWOptimization",
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "Logging", package: "swift-log"),
      ],
      path: "Sources/Netbot/Profile"
    ),
    .target(
      name: "NetbotXPC",
      dependencies: [
        "SynchronizationExtras",
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .target(name: "NetbotSQL", dependencies: ["NetbotSQLMacros"]),
    .target(
      name: "SynchronizationExtras",
      dependencies: [
        "SynchronizationMacros",
        .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
        .product(name: "Atomics", package: "swift-atomics"),
      ]),
    .testTarget(
      name: "CoWOptimizationMacrosTests",
      dependencies: [
        "CoWOptimizationMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(name: "NetbotDashboardTests", dependencies: ["NetbotDashboard"]),
    .testTarget(name: "NetbotDNSTests", dependencies: ["NetbotDNS"]),
    .testTarget(
      name: "NetbotFrontendMacrosTests",
      dependencies: [
        "NetbotFrontendMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(name: "NetbotFrontendTests", dependencies: ["NetbotFrontend"]),
    .testTarget(name: "NetbotLiteDataTests", dependencies: ["NetbotLiteData"]),
    .testTarget(name: "NetbotLiteTests", dependencies: ["NetbotLite"]),
    .testTarget(name: "NetbotProfileTests", dependencies: ["NetbotProfile"]),
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
    .testTarget(
      name: "NetbotSQLMacrosTests",
      dependencies: [
        "NetbotSQLMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SynchronizationMacrosTests",
      dependencies: [
        "SynchronizationMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)

if Context.environment["SWTNE_REQUIRES_LOCAL_DEPS"] != nil {
  package.dependencies += [
    .package(path: "../swift-netbot-protoimpl"),
    .package(path: "../swift-maxminddb"),
    .package(path: "../swift-preference"),
  ]
} else {
  package.dependencies += [
    .package(url: "https://github.com/hdtls/swift-netbot-protoimpl.git", branch: "main"),
    .package(url: "https://github.com/hdtls/swift-maxminddb.git", from: "1.3.0"),
    .package(url: "https://github.com/hdtls/swift-preference.git", from: "1.0.0"),
  ]
}

for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(.define("SWTNE_REQUIRES_LWIP", .when(platforms: [.macOS])))
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
