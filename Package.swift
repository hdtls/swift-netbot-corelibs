// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// See LICENSE.txt for license information
//

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-netbot-corelibs",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
  ],
  products: [
    .library(name: "_NEAnalytics", targets: ["_NEAnalytics"]),
    .library(name: "_PrivilegeSupport", targets: ["_PrivilegeSupport"]),
    .library(name: "Dashboard", targets: ["Dashboard"]),
    .library(name: "Netbot", targets: ["Netbot"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-asn1.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-certificates.git", from: "1.0.1"),
    .package(url: "https://github.com/apple/swift-crypto.git", "3.12.0"..<"3.13.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.32.1"),
    .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.14.1"),
    .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.25.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.4.0"),
    .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.3.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2"),
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
      name: "EditableMacros",
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
        .product(name: "NEAddressProcessing", package: "swift-netbot-framing"),
      ]
    ),
    .target(
      name: "_NEAnalytics",
      dependencies: [
        "_DNSSupport",
        "_PreferenceSupport",
        "_ProfileSupport",
        "_PrivilegeSupport",
        "Anlzr",
        "CNELwIP",
        "CoWOptimization",
        .product(name: "MaxMindDB", package: "swift-maxminddb"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "X509", package: "swift-certificates"),
        .product(name: "Alamofire", package: "Alamofire"),
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
    .target(
      name: "Anlzr",
      dependencies: [
        "AnlzrReports",
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
        .product(name: "NEHTTP", package: "swift-netbot-framing"),
        .product(name: "NESOCKS", package: "swift-netbot-framing"),
        .product(name: "NESS", package: "swift-netbot-framing"),
        .product(name: "NEVMESS", package: "swift-netbot-framing"),
      ]
    ),
    .target(
      name: "AnlzrReports",
      dependencies: [
        "SynchronizationMacros",
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "NEAddressProcessing", package: "swift-netbot-framing"),
        .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
      ]
    ),
    .target(name: "CNELwIP"),
    .target(name: "CoWOptimization", dependencies: ["CoWOptimizationMacros"]),
    .target(
      name: "Dashboard",
      dependencies: [
        "_PreferenceSupport",
        "AnlzrReports",
        .product(name: "NIOCore", package: "swift-nio"),
      ]
    ),
    .target(
      name: "Netbot",
      dependencies: [
        "_PreferenceSupport",
        "_ProfileSupport",
        "AnlzrReports",
        "Dashboard",
        "EditableMacros",
        .product(name: "_CryptoExtras", package: "swift-crypto"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "SwiftASN1", package: "swift-asn1"),
        .product(name: "X509", package: "swift-certificates"),
        .product(name: "Alamofire", package: "Alamofire"),
      ]
    ),
    .testTarget(name: "_DNSSupportTests", dependencies: ["_DNSSupport"]),
    .testTarget(
      name: "_NEAnalyticsTests",
      dependencies: ["_NEAnalytics"],
      exclude: ["External Resource"]
    ),
    .testTarget(name: "_ProfileSupportTests", dependencies: ["_ProfileSupport"]),
    .testTarget(
      name: "AnlzrReportsTests",
      dependencies: [
        "AnlzrReports"
      ]
    ),
    .testTarget(
      name: "AnlzrTests",
      dependencies: [
        "Anlzr",
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOEmbedded", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "NIOWebSocket", package: "swift-nio"),
      ]
    ),
    .testTarget(
      name: "CoWOptimizationMacrosTests",
      dependencies: [
        "CoWOptimizationMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "EditableMacrosTests",
      dependencies: [
        "EditableMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(name: "NetbotTests", dependencies: ["Netbot"]),
    .testTarget(
      name: "SynchronizationMacrosTests",
      dependencies: [
        "SynchronizationMacros",
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)

if Context.environment["ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA"] != nil {
  for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(.define("ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA"))
    target.swiftSettings = settings
  }
}

if Context.environment["ENABLE_LOCAL_PACKAGE_DEPENDENCIES"] == nil {
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.24.0"),
    .package(url: "https://github.com/hdtls/swift-netbot-framing.git", branch: "main"),
    .package(url: "https://github.com/hdtls/swift-maxminddb.git", from: "1.3.0"),
    .package(url: "https://github.com/hdtls/swift-preference.git", from: "1.0.0"),
  ]
} else {
  package.dependencies += [
    .package(path: "../swift-nio-transport-services"),
    .package(path: "../swift-netbot-framing"),
    .package(path: "../swift-maxminddb"),
    .package(path: "../swift-preference"),
  ]
}

for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(.enableExperimentalFeature("StrictConcurrency=complete"))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 5.3:iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0"))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 5.5:iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0"))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 5.7:iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0"))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 5.9:iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0"))
  settings.append(
    .enableExperimentalFeature(
      "AvailabilityMacro=SwiftStdlib 6.0:iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0"))
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
